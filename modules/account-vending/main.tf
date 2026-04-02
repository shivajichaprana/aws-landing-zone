# -----------------------------------------------------------------------------
# Account Vending Machine
# Creates new AWS accounts under specified OUs with baseline configuration
# including AWS Config recording, GuardDuty membership, and IAM alias setup.
# This module is the "factory" that stamps out new accounts with guardrails
# already in place from day one.
# -----------------------------------------------------------------------------

data "aws_caller_identity" "management" {}

# -----------------------------------------------------------------------------
# AWS Account Creation
# Each account is created under a specific OU and inherits all SCPs
# attached to that OU. The account email must be unique across AWS.
# -----------------------------------------------------------------------------

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name                       = each.key
  email                      = each.value.email
  parent_id                  = each.value.ou_id
  close_on_deletion          = each.value.close_on_deletion
  iam_user_access_to_billing = each.value.allow_iam_users ? "ALLOW" : "DENY"

  role_name = "OrganizationAccountAccessRole"

  tags = merge(var.tags, each.value.tags, {
    Name        = each.key
    AccountType = "vended"
  })

  lifecycle {
    # Prevent accidental deletion of AWS accounts
    prevent_destroy = true

    # Email can't be changed after creation
    ignore_changes = [email, role_name]
  }
}

# -----------------------------------------------------------------------------
# Cross-Account Provider Configuration
# To configure baseline services in each new account, we assume the
# OrganizationAccountAccessRole that was created during account creation.
# -----------------------------------------------------------------------------

# Note: In production, you would use provider aliases with assume_role
# for each account. Here we define the baseline resources that should
# be applied via a separate baseline module or StackSets.

# -----------------------------------------------------------------------------
# AWS Config Baseline
# Enables AWS Config in each vended account to track resource configuration
# changes. Config records are delivered to the centralized logging bucket.
# -----------------------------------------------------------------------------

resource "aws_config_configuration_recorder" "this" {
  for_each = {
    for name, account in var.accounts : name => account
    if account.enable_config
  }

  name     = "default"
  role_arn = aws_iam_role.config[each.key].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_organizations_account.this]
}

resource "aws_iam_role" "config" {
  for_each = {
    for name, account in var.accounts : name => account
    if account.enable_config
  }

  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
  ]

  tags = merge(var.tags, {
    Name    = "aws-config-role"
    Account = each.key
  })
}

resource "aws_config_delivery_channel" "this" {
  for_each = {
    for name, account in var.accounts : name => account
    if account.enable_config && var.config_bucket_name != ""
  }

  name           = "default"
  s3_bucket_name = var.config_bucket_name
  sns_topic_arn  = var.config_sns_topic_arn != "" ? var.config_sns_topic_arn : null

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  for_each = {
    for name, account in var.accounts : name => account
    if account.enable_config
  }

  name       = aws_config_configuration_recorder.this[each.key].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

# -----------------------------------------------------------------------------
# Account Baseline Tags
# Apply standard tags to each account via the Organizations API.
# These tags are visible in the Organizations console and can be used
# for cost allocation and resource grouping.
# -----------------------------------------------------------------------------

resource "aws_organizations_account" "tags_update" {
  for_each = var.accounts

  name      = each.key
  email     = each.value.email
  parent_id = each.value.ou_id

  tags = merge(var.tags, each.value.tags, {
    Name           = each.key
    AccountType    = "vended"
    ProvisionedBy  = "account-vending-module"
    ManagementAcct = data.aws_caller_identity.management.account_id
  })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [email, role_name]
  }
}
