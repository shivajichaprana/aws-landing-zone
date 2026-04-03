###############################################################################
# TFLint Configuration — AWS Landing Zone
# Enforces AWS best practices and catches common Terraform mistakes.
###############################################################################

config {
  # Enable module inspection for deeper analysis
  module = true

  # Enforce all rules by default
  force = false
}

# ---------------------------------------------------------------------------
# AWS Provider Plugin — catches AWS-specific misconfigurations
# ---------------------------------------------------------------------------
plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# ---------------------------------------------------------------------------
# Terraform Language Rules
# ---------------------------------------------------------------------------

# Disallow deprecated interpolation-only expressions: "${var.foo}" → var.foo
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Enforce consistent naming conventions (snake_case)
rule "terraform_naming_convention" {
  enabled = true
}

# Warn on unused declarations (variables, data sources, locals)
rule "terraform_unused_declarations" {
  enabled = true
}

# Require type declarations on all variables
rule "terraform_typed_variables" {
  enabled = true
}

# Require descriptions on all outputs
rule "terraform_documented_outputs" {
  enabled = true
}

# Require descriptions on all variables
rule "terraform_documented_variables" {
  enabled = true
}

# Enforce standard module structure
rule "terraform_standard_module_structure" {
  enabled = true
}
