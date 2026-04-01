variable "permission_sets" {
  description = "Map of permission set configurations to create in IAM Identity Center"
  type = map(object({
    description      = string
    session_duration = optional(string, "PT4H")
    managed_policies = optional(list(string), [])
    inline_policy    = optional(string, "")
    tags             = optional(map(string), {})
  }))

  default = {
    AdministratorAccess = {
      description      = "Full administrator access to the AWS account"
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    PowerUserAccess = {
      description      = "Power user access — full access except IAM and Organizations"
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
    ReadOnlyAccess = {
      description      = "Read-only access to all AWS services and resources"
      session_duration = "PT8H"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    SecurityAudit = {
      description      = "Security audit access for compliance and security reviews"
      session_duration = "PT8H"
      managed_policies = ["arn:aws:iam::aws:policy/SecurityAudit"]
    }
  }
}

variable "account_assignments" {
  description = "List of account-to-group-to-permission-set assignments"
  type = list(object({
    account_id       = string
    permission_set   = string
    principal_name   = string
    principal_type   = optional(string, "GROUP")
  }))
  default = []

  validation {
    condition = alltrue([
      for a in var.account_assignments : contains(["GROUP", "USER"], a.principal_type)
    ])
    error_message = "principal_type must be either GROUP or USER."
  }
}

variable "groups" {
  description = "Map of SSO groups to create in IAM Identity Center"
  type = map(object({
    description = string
  }))
  default = {
    Admins = {
      description = "Organization administrators with full access"
    }
    Developers = {
      description = "Development team with power user access"
    }
    ReadOnly = {
      description = "Read-only access for auditors and stakeholders"
    }
    SecurityTeam = {
      description = "Security team for audit and compliance"
    }
  }
}

variable "tags" {
  description = "Tags to apply to SSO resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "sso"
  }
}
