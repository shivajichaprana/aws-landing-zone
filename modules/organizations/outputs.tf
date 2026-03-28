###############################################################################
# Outputs — AWS Organizations Module
###############################################################################

output "organization_id" {
  description = "The ID of the AWS Organization."
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "The ARN of the AWS Organization."
  value       = aws_organizations_organization.this.arn
}

output "root_id" {
  description = "The ID of the organization root."
  value       = aws_organizations_organization.this.roots[0].id
}

output "ou_ids" {
  description = "Map of OU logical names to their IDs."
  value = {
    security       = aws_organizations_organizational_unit.security.id
    infrastructure = aws_organizations_organizational_unit.infrastructure.id
    workloads      = aws_organizations_organizational_unit.workloads.id
    sandbox        = aws_organizations_organizational_unit.sandbox.id
  }
}

output "ou_arns" {
  description = "Map of OU logical names to their ARNs."
  value = {
    security       = aws_organizations_organizational_unit.security.arn
    infrastructure = aws_organizations_organizational_unit.infrastructure.arn
    workloads      = aws_organizations_organizational_unit.workloads.arn
    sandbox        = aws_organizations_organizational_unit.sandbox.arn
  }
}

output "master_account_id" {
  description = "The AWS account ID of the management (master) account."
  value       = aws_organizations_organization.this.master_account_id
}
