# -----------------------------------------------------------------------------
# Complete Landing Zone Example
# Wires all 5 modules together to provision a full AWS multi-account
# landing zone: Organizations → SCPs → SSO → Logging → Account Vending
#
# Usage:
#   1. Copy terraform.tfvars.example to terraform.tfvars
#   2. Fill in your values
#   3. terraform init && terraform plan && terraform apply
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Recommended: configure remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "landing-zone/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-landing-zone"
      Environment = "management"
      ManagedBy   = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Module 1: AWS Organizations
# Creates the organization structure with OUs for Security, Infrastructure,
# Workloads, and Sandbox environments.
# -----------------------------------------------------------------------------

module "organizations" {
  source = "../../modules/organizations"

  feature_set = "ALL"

  ou_names = {
    security       = "Security"
    infrastructure = "Infrastructure"
    workloads      = "Workloads"
    sandbox        = "Sandbox"
  }

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "sso.amazonaws.com",
    "ram.amazonaws.com",
  ]

  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Module 2: Service Control Policies
# Attaches guardrail SCPs to all OUs — deny root, restrict regions,
# require encryption, prevent org leave.
# -----------------------------------------------------------------------------

module "scp" {
  source = "../../modules/scp"

  target_ou_ids   = module.organizations.ou_ids
  allowed_regions = var.allowed_regions

  enable_deny_root_account  = true
  enable_deny_leave_org     = true
  enable_restrict_regions   = true
  enable_require_encryption = true

  # Don't restrict regions on the Security OU (needs global service access)
  exclude_ous_from_region_restriction = ["security"]

  tags = var.tags

  depends_on = [module.organizations]
}

# -----------------------------------------------------------------------------
# Module 3: IAM Identity Center (SSO)
# Sets up permission sets and groups for centralized access management
# across all accounts in the organization.
# -----------------------------------------------------------------------------

module "sso" {
  source = "../../modules/sso"

  permission_sets = {
    AdministratorAccess = {
      description      = "Full administrator access"
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    PowerUserAccess = {
      description      = "Power user access — no IAM or Organizations"
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
    ReadOnlyAccess = {
      description      = "Read-only access for auditors"
      session_duration = "PT8H"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    SecurityAudit = {
      description      = "Security audit access"
      session_duration = "PT8H"
      managed_policies = ["arn:aws:iam::aws:policy/SecurityAudit"]
    }
  }

  groups = {
    Admins       = { description = "Organization administrators" }
    Developers   = { description = "Development team" }
    ReadOnly     = { description = "Read-only stakeholders" }
    SecurityTeam = { description = "Security and compliance team" }
  }

  account_assignments = var.sso_account_assignments

  tags = var.tags

  depends_on = [module.organizations]
}

# -----------------------------------------------------------------------------
# Module 4: Centralized Logging
# Organization-wide CloudTrail with encrypted S3 storage and CloudWatch
# integration for real-time monitoring.
# -----------------------------------------------------------------------------

module "logging" {
  source = "../../modules/logging"

  organization_id     = module.organizations.organization_id
  management_account_id = data.aws_caller_identity.current.account_id
  trail_name          = "${var.org_name}-cloudtrail"
  logging_bucket_name = "${var.org_name}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"

  log_retention_days      = var.log_retention_days
  glacier_transition_days = 365
  enable_s3_data_events   = false

  tags = var.tags

  depends_on = [module.organizations]
}

# -----------------------------------------------------------------------------
# Module 5: Account Vending
# Creates new AWS accounts under the appropriate OUs with baseline
# configuration (Config, GuardDuty, IAM alias).
# -----------------------------------------------------------------------------

module "account_vending" {
  source = "../../modules/account-vending"

  accounts = var.vended_accounts

  config_bucket_name = module.logging.logging_bucket_id

  tags = var.tags

  depends_on = [
    module.organizations,
    module.scp,
    module.logging,
  ]
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
