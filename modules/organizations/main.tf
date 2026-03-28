###############################################################################
# AWS Organizations Module
# Creates the organization, root OUs, and enables service access principals.
###############################################################################

resource "aws_organizations_organization" "this" {
  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types
  feature_set                   = var.feature_set
}

# -----------------------------------------------------------------------------
# Organizational Units — top-level structure
# -----------------------------------------------------------------------------

resource "aws_organizations_organizational_unit" "security" {
  name      = var.ou_names["security"]
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, {
    Purpose = "Security and audit accounts"
  })
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = var.ou_names["infrastructure"]
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, {
    Purpose = "Shared infrastructure accounts (networking, DNS, CI/CD)"
  })
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = var.ou_names["workloads"]
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, {
    Purpose = "Production and staging workload accounts"
  })
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = var.ou_names["sandbox"]
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = merge(var.tags, {
    Purpose = "Developer sandbox and experimentation accounts"
  })
}
