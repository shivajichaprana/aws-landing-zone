output "sso_instance_arn" {
  description = "ARN of the IAM Identity Center instance"
  value       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

output "identity_store_id" {
  description = "Identity Store ID associated with the SSO instance"
  value       = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

output "permission_set_arns" {
  description = "Map of permission set names to their ARNs"
  value = {
    for name, ps in aws_ssoadmin_permission_set.this : name => ps.arn
  }
}

output "group_ids" {
  description = "Map of group names to their Identity Store group IDs"
  value = {
    for name, group in aws_identitystore_group.this : name => group.group_id
  }
}

output "assignment_ids" {
  description = "List of account assignment identifiers"
  value = [
    for key, assignment in aws_ssoadmin_account_assignment.this : {
      account_id     = assignment.target_id
      permission_set = assignment.permission_set_arn
      principal      = assignment.principal_id
    }
  ]
}
