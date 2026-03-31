variable "target_ou_ids" {
  description = "Map of OU names to OU IDs where SCPs will be attached"
  type        = map(string)

  validation {
    condition     = length(var.target_ou_ids) > 0
    error_message = "At least one target OU must be specified."
  }
}

variable "allowed_regions" {
  description = "List of AWS regions that are permitted for resource creation"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "eu-west-1"]

  validation {
    condition     = length(var.allowed_regions) > 0
    error_message = "At least one allowed region must be specified."
  }
}

variable "enable_deny_root_account" {
  description = "Enable SCP that denies all actions by the root user in member accounts"
  type        = bool
  default     = true
}

variable "enable_deny_leave_org" {
  description = "Enable SCP that prevents accounts from leaving the organization"
  type        = bool
  default     = true
}

variable "enable_restrict_regions" {
  description = "Enable SCP that restricts resource creation to allowed regions only"
  type        = bool
  default     = true
}

variable "enable_require_encryption" {
  description = "Enable SCP that requires encryption on S3 buckets and EBS volumes"
  type        = bool
  default     = true
}

variable "exclude_ous_from_region_restriction" {
  description = "List of OU names to exclude from region restriction SCP (e.g., global services OU)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to SCP resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "scp"
  }
}
