# Organizations Module

Creates an AWS Organization with a multi-OU hierarchy, service integrations, and policy type enablement. This is the foundational module — all other modules depend on its outputs.

## What This Module Creates

- AWS Organization with `ALL` feature set (enables SCPs and other policy types)
- Configurable Organizational Units (OUs) under the organization root
- Trusted service access for AWS services (CloudTrail, Config, SSO, GuardDuty, etc.)
- Organization-level policy type enablement (SCP, Tag Policy)

## Usage

```hcl
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
    "sso.amazonaws.com",
    "guardduty.amazonaws.com",
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]

  tags = {
    Environment = "management"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `feature_set` | Feature set for the organization. `ALL` enables SCPs and other policy types. | `string` | `"ALL"` | no |
| `ou_names` | Map of OU logical names to display names. Keys are used as identifiers in outputs. | `map(string)` | `{security = "Security", infrastructure = "Infrastructure", workloads = "Workloads", sandbox = "Sandbox"}` | no |
| `aws_service_access_principals` | List of AWS service principals to enable trusted access for in the organization. | `list(string)` | `["cloudtrail.amazonaws.com", "config.amazonaws.com", "sso.amazonaws.com", "guardduty.amazonaws.com", "access-analyzer.amazonaws.com", "tagpolicies.tag.amazonaws.com"]` | no |
| `enabled_policy_types` | List of organization policy types to enable (e.g., SERVICE_CONTROL_POLICY, TAG_POLICY). | `list(string)` | `["SERVICE_CONTROL_POLICY", "TAG_POLICY"]` | no |
| `tags` | Tags applied to all resources in this module. | `map(string)` | `{ManagedBy = "terraform", Module = "organizations"}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `organization_id` | The ID of the AWS Organization |
| `organization_arn` | The ARN of the AWS Organization |
| `root_id` | The ID of the organization root |
| `ou_ids` | Map of OU logical names to their IDs |
| `ou_arns` | Map of OU logical names to their ARNs |
| `master_account_id` | The AWS account ID of the management (master) account |

## Notes

- This module must be applied from the **management account** — it creates the organization itself.
- Destroying this module will attempt to delete the organization, which requires removing all member accounts first.
- The `ou_ids` output is consumed by the SCP module to attach policies and by the Account Vending module to place new accounts.
- Changing `ou_names` keys will destroy and recreate OUs — use caution with existing accounts.
