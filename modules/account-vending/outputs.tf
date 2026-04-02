output "account_ids" {
  description = "Map of account names to their AWS account IDs"
  value = {
    for name, account in aws_organizations_account.this : name => account.id
  }
}

output "account_arns" {
  description = "Map of account names to their ARNs"
  value = {
    for name, account in aws_organizations_account.this : name => account.arn
  }
}

output "account_emails" {
  description = "Map of account names to their root email addresses"
  value = {
    for name, account in aws_organizations_account.this : name => account.email
  }
}

output "account_status" {
  description = "Map of account names to their status (ACTIVE, SUSPENDED, etc.)"
  value = {
    for name, account in aws_organizations_account.this : name => account.status
  }
}

output "config_recorder_ids" {
  description = "Map of account names to their AWS Config recorder IDs (if enabled)"
  value = {
    for name, recorder in aws_config_configuration_recorder.this : name => recorder.id
  }
}

output "provisioned_accounts" {
  description = "Summary of all provisioned accounts"
  value = {
    for name, account in aws_organizations_account.this : name => {
      id     = account.id
      arn    = account.arn
      email  = account.email
      ou_id  = var.accounts[name].ou_id
      status = account.status
    }
  }
}
