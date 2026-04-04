# SSO Module

Configures AWS IAM Identity Center (formerly AWS SSO) with permission sets, identity groups, and account assignments. This module provides centralized, role-based access control across all accounts in the organization.

## What This Module Creates

- Permission sets with configurable managed policies and inline policies
- Identity Store groups for team-based access management
- Account assignments mapping groups/users to permission sets on specific accounts

## Usage

```hcl
module "sso" {
  source = "../../modules/sso"

  permission_sets = {
    AdministratorAccess = {
      description      = "Full administrator access"
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    ReadOnlyAccess = {
      description      = "Read-only access for auditing"
      session_duration = "PT8H"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  groups = {
    Admins = {
      description = "Organization administrators"
    }
    Developers = {
      description = "Development team members"
    }
  }

  account_assignments = [
    {
      account_id     = "123456789012"
      permission_set = "AdministratorAccess"
      principal_name = "Admins"
      principal_type = "GROUP"
    },
    {
      account_id     = "123456789012"
      permission_set = "ReadOnlyAccess"
      principal_name = "Developers"
      principal_type = "GROUP"
    },
  ]

  tags = {
    ManagedBy = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `permission_sets` | Map of permission set configurations. Each key is the permission set name. | `map(object)` | AdministratorAccess, PowerUserAccess, ReadOnlyAccess, SecurityAudit | no |
| `groups` | Map of SSO groups to create in IAM Identity Center. | `map(object)` | Admins, Developers, ReadOnly, SecurityTeam | no |
| `account_assignments` | List of account-to-principal-to-permission-set assignments. | `list(object)` | `[]` | no |
| `tags` | Tags to apply to SSO resources. | `map(string)` | `{ManagedBy = "terraform", Module = "sso"}` | no |

### Permission Set Object

```hcl
{
  description      = string           # Description of the permission set
  session_duration = optional(string)  # ISO 8601 duration (default: "PT4H")
  managed_policies = optional(list)    # ARNs of AWS managed policies
  inline_policy    = optional(string)  # Custom inline policy JSON
  tags             = optional(map)     # Additional tags
}
```

### Account Assignment Object

```hcl
{
  account_id     = string            # Target AWS account ID
  permission_set = string            # Key from permission_sets map
  principal_name = string            # Group name or user name
  principal_type = optional(string)  # "GROUP" or "USER" (default: "GROUP")
}
```

## Outputs

| Name | Description |
|------|-------------|
| `sso_instance_arn` | ARN of the IAM Identity Center instance |
| `identity_store_id` | Identity Store ID associated with the SSO instance |
| `permission_set_arns` | Map of permission set names to their ARNs |
| `group_ids` | Map of group names to their Identity Store group IDs |
| `assignment_ids` | List of account assignment identifiers |

## Default Permission Sets

| Permission Set | Session Duration | AWS Managed Policy | Use Case |
|---------------|-----------------|-------------------|----------|
| AdministratorAccess | 4 hours | AdministratorAccess | Full admin for platform team |
| PowerUserAccess | 4 hours | PowerUserAccess | Developers (no IAM changes) |
| ReadOnlyAccess | 8 hours | ReadOnlyAccess | Auditors, read-only access |
| SecurityAudit | 8 hours | SecurityAudit | Security team investigations |

## Notes

- IAM Identity Center must be enabled in the management account before using this module. The module uses a `data` source to look up the existing SSO instance.
- Permission set names must be unique within the SSO instance.
- Account assignments require the target account to exist in the organization.
- Group membership is managed outside this module (via the IAM Identity Center console or SCIM provisioning from an external IdP).
- Session durations use ISO 8601 format: `PT1H` = 1 hour, `PT4H` = 4 hours, `PT8H` = 8 hours, `PT12H` = 12 hours (max).
