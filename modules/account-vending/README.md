# Account Vending Module

Automates the creation of new AWS accounts within the organization, placing them in the correct OU and applying baseline configurations (AWS Config recording, tagging). New accounts automatically inherit all SCPs attached to their target OU.

## What This Module Creates

- **AWS Accounts** — New member accounts under specified OUs with cross-account access role
- **AWS Config Baseline** — Configuration recorder and delivery channel in each account (optional)
- **Account Tagging** — Standardized tags applied via the Organizations API

## Usage

```hcl
module "account_vending" {
  source = "../../modules/account-vending"

  accounts = {
    log-archive = {
      email  = "aws+log-archive@company.com"
      ou_id  = module.organizations.ou_ids["security"]
      tags   = { Purpose = "Centralized logging" }
    }
    production = {
      email          = "aws+production@company.com"
      ou_id          = module.organizations.ou_ids["workloads"]
      enable_config  = true
      enable_guardduty = true
      tags           = { Purpose = "Production workloads" }
    }
    sandbox-dev = {
      email            = "aws+sandbox@company.com"
      ou_id            = module.organizations.ou_ids["sandbox"]
      close_on_deletion = true
      tags             = { Purpose = "Developer experimentation" }
    }
  }

  config_bucket_name  = module.logging.logging_bucket_id
  config_sns_topic_arn = aws_sns_topic.config_notifications.arn

  baseline_iam_alias_prefix = "myorg"

  tags = {
    ManagedBy = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `accounts` | Map of AWS accounts to create. Each key is the account name. See account object below. | `map(object)` | — | **yes** |
| `config_bucket_name` | S3 bucket name for AWS Config delivery. Must exist in the logging account. | `string` | `""` | no |
| `config_sns_topic_arn` | SNS topic ARN for AWS Config change notifications. | `string` | `""` | no |
| `guardduty_detector_id` | GuardDuty detector ID in the delegated admin account for member invitation. | `string` | `""` | no |
| `baseline_iam_alias_prefix` | Prefix for IAM account alias. Resulting alias: `<prefix>-<account-name>`. | `string` | `"org"` | no |
| `tags` | Default tags to apply to all vended accounts. | `map(string)` | `{ManagedBy = "terraform", Module = "account-vending"}` | no |

### Account Object

```hcl
{
  email             = string            # Unique email address (REQUIRED)
  ou_id             = string            # Target OU ID (REQUIRED)
  allow_iam_users   = optional(bool)    # Allow IAM users billing access (default: true)
  enable_config     = optional(bool)    # Enable AWS Config recording (default: true)
  enable_guardduty  = optional(bool)    # Enable GuardDuty membership (default: true)
  close_on_deletion = optional(bool)    # Close account on Terraform destroy (default: false)
  tags              = optional(map)     # Account-specific tags (merged with default tags)
}
```

## Outputs

| Name | Description |
|------|-------------|
| `account_ids` | Map of account names to their AWS account IDs |
| `account_arns` | Map of account names to their ARNs |
| `account_emails` | Map of account names to their root email addresses |
| `account_status` | Map of account names to their status (ACTIVE, SUSPENDED, etc.) |
| `config_recorder_ids` | Map of account names to their AWS Config recorder IDs (if enabled) |
| `provisioned_accounts` | Summary of all provisioned accounts with ID, ARN, email, OU, and status |

## Notes

- Each AWS account requires a **globally unique email address**. Use email aliases (e.g., `aws+name@company.com`) to create multiple accounts from one mailbox.
- New accounts get an `OrganizationAccountAccessRole` IAM role automatically, allowing the management account to assume into them for bootstrapping.
- The `prevent_destroy` lifecycle rule is set on account resources to prevent accidental deletion. Set `close_on_deletion = true` explicitly for accounts you want Terraform to close on destroy.
- AWS Config baseline requires the config S3 bucket to exist and have a bucket policy allowing cross-account delivery.
- Account creation is eventually consistent — it may take a few minutes for a new account to be fully functional.
- Moving an account to a different OU (by changing `ou_id`) will change which SCPs apply to it.
