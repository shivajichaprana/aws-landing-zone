# -----------------------------------------------------------------------------
# Service Control Policies (SCPs)
# Guardrails enforced across the AWS Organization at the OU level.
# Each policy can be independently enabled/disabled via variables.
# -----------------------------------------------------------------------------

locals {
  # OUs that should receive the region restriction SCP
  region_restricted_ous = {
    for name, id in var.target_ou_ids :
    name => id if !contains(var.exclude_ous_from_region_restriction, name)
  }
}

# -----------------------------------------------------------------------------
# SCP 1: Deny Root Account Usage
# Prevents the root user in member accounts from performing any action.
# This is an AWS security best practice — root should never be used in
# member accounts after initial setup.
# -----------------------------------------------------------------------------

resource "aws_organizations_policy" "deny_root_account" {
  count = var.enable_deny_root_account ? 1 : 0

  name        = "deny-root-account-usage"
  description = "Deny all actions performed by the root user in member accounts"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/deny-root-account.json")
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "deny_root_account" {
  for_each = var.enable_deny_root_account ? var.target_ou_ids : {}

  policy_id = aws_organizations_policy.deny_root_account[0].id
  target_id = each.value
}

# -----------------------------------------------------------------------------
# SCP 2: Deny Leaving the Organization
# Prevents member accounts from calling organizations:LeaveOrganization.
# Without this, any account admin could detach from the org.
# -----------------------------------------------------------------------------

resource "aws_organizations_policy" "deny_leave_org" {
  count = var.enable_deny_leave_org ? 1 : 0

  name        = "deny-leave-organization"
  description = "Prevent member accounts from leaving the AWS Organization"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/deny-leave-organization.json")
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "deny_leave_org" {
  for_each = var.enable_deny_leave_org ? var.target_ou_ids : {}

  policy_id = aws_organizations_policy.deny_leave_org[0].id
  target_id = each.value
}

# -----------------------------------------------------------------------------
# SCP 3: Restrict AWS Regions
# Limits resource creation to an approved list of regions. Global services
# (IAM, Route53, CloudFront, etc.) are exempted so they continue to work.
# Some OUs can be excluded via var.exclude_ous_from_region_restriction.
# -----------------------------------------------------------------------------

resource "aws_organizations_policy" "restrict_regions" {
  count = var.enable_restrict_regions ? 1 : 0

  name        = "restrict-allowed-regions"
  description = "Restrict resource creation to approved AWS regions only"
  type        = "SERVICE_CONTROL_POLICY"

  content = templatefile("${path.module}/policies/restrict-regions.json", {
    allowed_regions = jsonencode(var.allowed_regions)
  })

  tags = var.tags
}

resource "aws_organizations_policy_attachment" "restrict_regions" {
  for_each = var.enable_restrict_regions ? local.region_restricted_ous : {}

  policy_id = aws_organizations_policy.restrict_regions[0].id
  target_id = each.value
}

# -----------------------------------------------------------------------------
# SCP 4: Require Encryption
# Denies creation of unencrypted S3 buckets and unencrypted EBS volumes.
# Forces teams to use encryption by default — a compliance requirement
# for most security frameworks (SOC2, HIPAA, PCI-DSS).
# -----------------------------------------------------------------------------

resource "aws_organizations_policy" "require_encryption" {
  count = var.enable_require_encryption ? 1 : 0

  name        = "require-encryption"
  description = "Deny creation of unencrypted S3 buckets and EBS volumes"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/require-encryption.json")
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "require_encryption" {
  for_each = var.enable_require_encryption ? var.target_ou_ids : {}

  policy_id = aws_organizations_policy.require_encryption[0].id
  target_id = each.value
}
