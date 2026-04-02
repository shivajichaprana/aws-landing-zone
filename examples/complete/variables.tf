variable "aws_region" {
  description = "Primary AWS region for the landing zone"
  type        = string
  default     = "us-east-1"
}

variable "org_name" {
  description = "Organization name — used as a prefix for resource naming"
  type        = string
}

variable "allowed_regions" {
  description = "AWS regions allowed for resource creation"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "eu-west-1"]
}

variable "log_retention_days" {
  description = "Number of days to retain CloudTrail logs"
  type        = number
  default     = 90
}

variable "sso_account_assignments" {
  description = "SSO account-to-group-to-permission-set assignments"
  type = list(object({
    account_id     = string
    permission_set = string
    principal_name = string
    principal_type = optional(string, "GROUP")
  }))
  default = []
}

variable "vended_accounts" {
  description = "Map of AWS accounts to create via the account vending module"
  type = map(object({
    email             = string
    ou_id             = string
    allow_iam_users   = optional(bool, true)
    enable_config     = optional(bool, true)
    enable_guardduty  = optional(bool, true)
    close_on_deletion = optional(bool, false)
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "aws-landing-zone"
  }
}
