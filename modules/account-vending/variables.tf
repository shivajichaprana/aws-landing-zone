variable "accounts" {
  description = "Map of AWS accounts to create. Each account is placed under its target OU with baseline configuration."
  type = map(object({
    email             = string
    ou_id             = string
    allow_iam_users   = optional(bool, true)
    enable_config     = optional(bool, true)
    enable_guardduty  = optional(bool, true)
    close_on_deletion = optional(bool, false)
    tags              = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for name, account in var.accounts : can(regex("^[^@]+@[^@]+\\.[^@]+$", account.email))
    ])
    error_message = "Each account must have a valid email address."
  }
}

variable "config_bucket_name" {
  description = "S3 bucket name for AWS Config delivery (must exist in the logging account)"
  type        = string
  default     = ""
}

variable "config_sns_topic_arn" {
  description = "SNS topic ARN for AWS Config notifications"
  type        = string
  default     = ""
}

variable "guardduty_detector_id" {
  description = "GuardDuty detector ID in the delegated admin account for member invitation"
  type        = string
  default     = ""
}

variable "baseline_iam_alias_prefix" {
  description = "Prefix for IAM account alias (will be suffixed with account name)"
  type        = string
  default     = "org"
}

variable "tags" {
  description = "Default tags to apply to all vended accounts"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "account-vending"
  }
}
