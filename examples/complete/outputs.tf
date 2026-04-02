output "organization_id" {
  description = "AWS Organization ID"
  value       = module.organizations.organization_id
}

output "ou_ids" {
  description = "Map of OU names to their IDs"
  value       = module.organizations.ou_ids
}

output "active_scps" {
  description = "List of active Service Control Policies"
  value       = module.scp.active_policies
}

output "sso_permission_set_arns" {
  description = "Map of SSO permission set names to ARNs"
  value       = module.sso.permission_set_arns
}

output "cloudtrail_arn" {
  description = "ARN of the organization CloudTrail"
  value       = module.logging.cloudtrail_arn
}

output "logging_bucket_arn" {
  description = "ARN of the centralized logging bucket"
  value       = module.logging.logging_bucket_arn
}

output "logging_kms_key_arn" {
  description = "ARN of the KMS key for log encryption"
  value       = module.logging.kms_key_arn
}

output "vended_account_ids" {
  description = "Map of vended account names to their AWS account IDs"
  value       = module.account_vending.account_ids
}
