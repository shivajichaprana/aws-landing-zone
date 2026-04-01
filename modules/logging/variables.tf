variable "organization_id" {
  description = "AWS Organization ID — used in S3 bucket policy to allow org-wide CloudTrail delivery"
  type        = string

  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "organization_id must be a valid AWS Organization ID (e.g., o-abc123def4)."
  }
}

variable "trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "org-cloudtrail"
}

variable "logging_bucket_name" {
  description = "Name of the S3 bucket for centralized CloudTrail log storage"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.logging_bucket_name))
    error_message = "logging_bucket_name must be a valid S3 bucket name."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain CloudTrail logs before transitioning to Glacier"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30
    error_message = "log_retention_days must be at least 30 days for compliance."
  }
}

variable "glacier_transition_days" {
  description = "Number of days after which logs are transitioned to Glacier for long-term storage"
  type        = number
  default     = 365
}

variable "enable_log_file_validation" {
  description = "Enable CloudTrail log file integrity validation"
  type        = bool
  default     = true
}

variable "enable_s3_data_events" {
  description = "Enable logging of S3 data events (read/write) across the organization"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window" {
  description = "Number of days before the KMS key is deleted after scheduling"
  type        = number
  default     = 30
}

variable "management_account_id" {
  description = "AWS Account ID of the management (root) account"
  type        = string
}

variable "tags" {
  description = "Tags to apply to logging resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "logging"
  }
}
