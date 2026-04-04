# Logging Module

Creates an organization-wide CloudTrail trail with encrypted S3 storage, CloudWatch Logs integration, and configurable lifecycle rules. All API activity across every account in the organization is captured in a centralized, tamper-resistant log archive.

## What This Module Creates

- **KMS Customer Managed Key** — Dedicated encryption key for CloudTrail logs with automatic rotation
- **S3 Bucket** — Centralized log storage with versioning, public access block, and lifecycle rules (Standard → Glacier → Delete)
- **S3 Bucket Policy** — Allows CloudTrail delivery from the organization, enforces HTTPS-only access
- **CloudWatch Log Group** — Real-time log streaming for alerting and monitoring
- **IAM Role** — Allows CloudTrail to deliver logs to CloudWatch
- **Organization CloudTrail** — Multi-region trail capturing all accounts

## Usage

```hcl
module "logging" {
  source = "../../modules/logging"

  organization_id    = module.organizations.organization_id
  management_account_id = data.aws_caller_identity.current.account_id
  logging_bucket_name = "org-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"

  trail_name          = "org-cloudtrail"
  log_retention_days  = 90
  glacier_transition_days = 365

  enable_log_file_validation = true
  enable_s3_data_events      = false  # Enable for S3 read/write audit (adds cost)

  tags = {
    ManagedBy = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `organization_id` | AWS Organization ID — used in the S3 bucket policy to allow org-wide CloudTrail delivery. | `string` | — | **yes** |
| `management_account_id` | AWS Account ID of the management (root) account. Used in the KMS key policy. | `string` | — | **yes** |
| `logging_bucket_name` | Name of the S3 bucket for centralized CloudTrail log storage. Must be globally unique. | `string` | — | **yes** |
| `trail_name` | Name of the CloudTrail trail. | `string` | `"org-cloudtrail"` | no |
| `log_retention_days` | Number of days to retain CloudTrail logs in S3 Standard before transitioning to Glacier. Minimum 30. | `number` | `90` | no |
| `glacier_transition_days` | Number of days after which logs transition from S3 Standard to Glacier. | `number` | `365` | no |
| `enable_log_file_validation` | Enable CloudTrail log file integrity validation (digest files). | `bool` | `true` | no |
| `enable_s3_data_events` | Enable logging of S3 data events (read/write) across the organization. Adds cost. | `bool` | `false` | no |
| `kms_key_deletion_window` | Number of days before the KMS key is permanently deleted after scheduling deletion. | `number` | `30` | no |
| `tags` | Tags to apply to logging resources. | `map(string)` | `{ManagedBy = "terraform", Module = "logging"}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cloudtrail_arn` | ARN of the organization CloudTrail trail |
| `cloudtrail_id` | Name of the CloudTrail trail |
| `logging_bucket_arn` | ARN of the centralized logging S3 bucket |
| `logging_bucket_id` | Name of the centralized logging S3 bucket |
| `kms_key_arn` | ARN of the KMS key used for CloudTrail log encryption |
| `kms_key_id` | ID of the KMS key used for CloudTrail log encryption |
| `log_group_arn` | ARN of the CloudWatch Log Group for CloudTrail |

## Log Lifecycle

```
API Call → CloudTrail → S3 (Standard) → Glacier (365d) → Deleted (455d)
                     ↘ CloudWatch Logs → Metric Filters → Alarms
```

The default lifecycle:

1. Logs land in S3 Standard storage (encrypted with KMS)
2. After 365 days, logs transition to S3 Glacier for cost-effective long-term storage
3. After 455 days (90 + 365), logs are permanently deleted
4. CloudWatch receives logs in real-time for monitoring and alerting

## Notes

- The organization trail captures management events from **all** accounts and **all** regions automatically.
- S3 data events are disabled by default because they generate high log volume and cost. Enable only if you need to audit S3 object-level access.
- The KMS key policy restricts decryption to the management account. Member accounts cannot read logs directly from S3 — access must go through a centralized log analysis tool.
- Log file validation creates digest files that allow you to verify logs haven't been tampered with. Keep this enabled.
- The S3 bucket has `force_destroy = false` by default — you must empty it before Terraform can destroy it.
