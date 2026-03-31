output "deny_root_account_policy_id" {
  description = "ID of the deny root account SCP"
  value       = var.enable_deny_root_account ? aws_organizations_policy.deny_root_account[0].id : null
}

output "deny_leave_org_policy_id" {
  description = "ID of the deny leave organization SCP"
  value       = var.enable_deny_leave_org ? aws_organizations_policy.deny_leave_org[0].id : null
}

output "restrict_regions_policy_id" {
  description = "ID of the restrict regions SCP"
  value       = var.enable_restrict_regions ? aws_organizations_policy.restrict_regions[0].id : null
}

output "require_encryption_policy_id" {
  description = "ID of the require encryption SCP"
  value       = var.enable_require_encryption ? aws_organizations_policy.require_encryption[0].id : null
}

output "policy_attachment_ids" {
  description = "Map of all SCP policy attachment IDs"
  value = merge(
    { for k, v in aws_organizations_policy_attachment.deny_root_account : k => v.id },
    { for k, v in aws_organizations_policy_attachment.deny_leave_org : k => v.id },
    { for k, v in aws_organizations_policy_attachment.restrict_regions : k => v.id },
    { for k, v in aws_organizations_policy_attachment.require_encryption : k => v.id },
  )
}

output "active_policies" {
  description = "List of active SCP policy names"
  value = compact([
    var.enable_deny_root_account ? "deny-root-account" : "",
    var.enable_deny_leave_org ? "deny-leave-organization" : "",
    var.enable_restrict_regions ? "restrict-regions" : "",
    var.enable_require_encryption ? "require-encryption" : "",
  ])
}
