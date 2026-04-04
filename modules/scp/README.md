# SCP Module

Creates and attaches Service Control Policies (SCPs) to organizational units. SCPs act as permission guardrails — they restrict what actions are allowed in member accounts, regardless of IAM policies.

## What This Module Creates

- **Deny Root Account** — Prevents the root user in member accounts from performing any action
- **Deny Leave Organization** — Prevents accounts from calling `organizations:LeaveOrganization`
- **Restrict Regions** — Limits resource creation to a configurable list of allowed regions (exempts global services like IAM, CloudFront, Route 53)
- **Require Encryption** — Denies creation of unencrypted S3 buckets and EBS volumes

Each SCP can be individually enabled or disabled via boolean variables.

## Usage

```hcl
module "scp" {
  source = "../../modules/scp"

  target_ou_ids = module.organizations.ou_ids

  allowed_regions = ["us-east-1", "us-west-2", "eu-west-1"]

  enable_deny_root_account  = true
  enable_deny_leave_org     = true
  enable_restrict_regions   = true
  enable_require_encryption = true

  # Security OU needs global access for CloudTrail, GuardDuty admin
  exclude_ous_from_region_restriction = ["security"]

  tags = {
    ManagedBy = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `target_ou_ids` | Map of OU names to OU IDs where SCPs will be attached. Typically `module.organizations.ou_ids`. | `map(string)` | — | **yes** |
| `allowed_regions` | List of AWS regions permitted for resource creation. | `list(string)` | `["us-east-1", "us-west-2", "eu-west-1"]` | no |
| `enable_deny_root_account` | Enable the SCP that denies all actions by root users in member accounts. | `bool` | `true` | no |
| `enable_deny_leave_org` | Enable the SCP that prevents accounts from leaving the organization. | `bool` | `true` | no |
| `enable_restrict_regions` | Enable the SCP that restricts resource creation to `allowed_regions`. | `bool` | `true` | no |
| `enable_require_encryption` | Enable the SCP that requires encryption on S3 buckets and EBS volumes. | `bool` | `true` | no |
| `exclude_ous_from_region_restriction` | List of OU names (keys from `target_ou_ids`) to exclude from the region restriction SCP. | `list(string)` | `[]` | no |
| `tags` | Tags to apply to SCP resources. | `map(string)` | `{ManagedBy = "terraform", Module = "scp"}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `deny_root_account_policy_id` | ID of the deny root account SCP |
| `deny_leave_org_policy_id` | ID of the deny leave organization SCP |
| `restrict_regions_policy_id` | ID of the restrict regions SCP |
| `require_encryption_policy_id` | ID of the require encryption SCP |
| `policy_attachment_ids` | Map of all SCP policy attachment IDs |
| `active_policies` | List of active SCP policy names |

## SCP Descriptions

### Deny Root Account Usage

Denies all actions (`*`) when the principal is the root user. This is an AWS security best practice — root credentials should never be used in member accounts. The management account is not affected by SCPs.

### Deny Leave Organization

Prevents member accounts from calling `organizations:LeaveOrganization`. Without this, an account admin could detach their account from the organization, removing all SCP protections.

### Restrict Regions

Denies all actions outside the allowed regions list. Exempts global services that don't have regional endpoints (IAM, STS, CloudFront, Route 53, Organizations, Budgets, WAF, etc.). Use `exclude_ous_from_region_restriction` for OUs that need broader access.

### Require Encryption

Denies `s3:PutObject` without server-side encryption and `ec2:CreateVolume` without encryption. Forces all data at rest to be encrypted as a baseline compliance control.

## Notes

- SCPs do not grant permissions — they only restrict them. An SCP cannot make an action succeed if no IAM policy allows it.
- SCPs apply to all users and roles in affected accounts, including the account root user — but not the management account.
- The management account is never affected by SCPs, even if attached.
- Enabling all four SCPs is recommended for production environments. Use the individual `enable_*` flags for gradual rollout.
