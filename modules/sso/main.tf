# -----------------------------------------------------------------------------
# IAM Identity Center (AWS SSO)
# Manages permission sets, groups, and account assignments for centralized
# role-based access control across the AWS Organization.
# -----------------------------------------------------------------------------

# Retrieve the existing SSO instance (auto-created when SSO is enabled)
data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  # Flatten account assignments for for_each
  account_assignments_flat = {
    for assignment in var.account_assignments :
    "${assignment.account_id}-${assignment.permission_set}-${assignment.principal_name}" => assignment
  }
}

# -----------------------------------------------------------------------------
# Permission Sets
# Define what level of access a user/group gets when assuming a role.
# Each permission set maps to an IAM role in the target account.
# -----------------------------------------------------------------------------

resource "aws_ssoadmin_permission_set" "this" {
  for_each = var.permission_sets

  name             = each.key
  description      = each.value.description
  instance_arn     = local.sso_instance_arn
  session_duration = each.value.session_duration

  tags = merge(var.tags, each.value.tags)
}

# Attach AWS managed policies to permission sets
resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = {
    for item in flatten([
      for ps_name, ps in var.permission_sets : [
        for policy_arn in ps.managed_policies : {
          key        = "${ps_name}-${policy_arn}"
          ps_name    = ps_name
          policy_arn = policy_arn
        }
      ]
    ]) : item.key => item
  }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.ps_name].arn
  managed_policy_arn = each.value.policy_arn
}

# Attach inline policies to permission sets (if provided)
resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  for_each = {
    for name, ps in var.permission_sets : name => ps
    if ps.inline_policy != ""
  }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  inline_policy      = each.value.inline_policy
}

# -----------------------------------------------------------------------------
# Identity Store Groups
# Groups in the Identity Store that users are assigned to. These groups
# are then mapped to permission sets on specific accounts.
# -----------------------------------------------------------------------------

resource "aws_identitystore_group" "this" {
  for_each = var.groups

  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = each.value.description
}

# -----------------------------------------------------------------------------
# Account Assignments
# Maps a principal (group or user) to a permission set on a target account.
# This is the core of SSO — it defines "who gets what access where."
# -----------------------------------------------------------------------------

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.account_assignments_flat

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn

  principal_id   = each.value.principal_type == "GROUP" ? aws_identitystore_group.this[each.value.principal_name].group_id : each.value.principal_name
  principal_type = each.value.principal_type

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}
