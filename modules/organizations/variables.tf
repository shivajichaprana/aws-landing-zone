###############################################################################
# Variables — AWS Organizations Module
###############################################################################

variable "feature_set" {
  description = "Feature set for the organization. ALL enables SCPs and other policy types."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "CONSOLIDATED_BILLING"], var.feature_set)
    error_message = "feature_set must be ALL or CONSOLIDATED_BILLING."
  }
}

variable "ou_names" {
  description = "Map of OU logical names to display names."
  type        = map(string)
  default = {
    security       = "Security"
    infrastructure = "Infrastructure"
    workloads      = "Workloads"
    sandbox        = "Sandbox"
  }
}

variable "aws_service_access_principals" {
  description = "List of AWS service principals to enable trusted access for."
  type        = list(string)
  default = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "guardduty.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "tagpolicies.tag.amazonaws.com",
  ]
}

variable "enabled_policy_types" {
  description = "List of organization policy types to enable."
  type        = list(string)
  default = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "organizations"
  }
}
