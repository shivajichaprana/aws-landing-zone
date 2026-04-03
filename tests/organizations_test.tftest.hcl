###############################################################################
# Tests — Organizations Module
# Validates OU structure, feature set defaults, and service access principals.
###############################################################################

# ---------------------------------------------------------------------------
# Default configuration — all defaults should produce a valid plan
# ---------------------------------------------------------------------------
run "default_feature_set_is_all" {
  command = plan

  module {
    source = "./modules/organizations"
  }

  assert {
    condition     = var.feature_set == "ALL"
    error_message = "Default feature_set should be ALL to enable SCPs and tag policies."
  }
}

run "default_ou_structure_has_four_ous" {
  command = plan

  module {
    source = "./modules/organizations"
  }

  assert {
    condition     = length(var.ou_names) == 4
    error_message = "Default OU structure should define exactly 4 OUs (security, infrastructure, workloads, sandbox)."
  }
}

run "default_ou_contains_security" {
  command = plan

  module {
    source = "./modules/organizations"
  }

  assert {
    condition     = contains(keys(var.ou_names), "security")
    error_message = "Default OU structure must include a 'security' OU."
  }
}

run "default_ou_contains_workloads" {
  command = plan

  module {
    source = "./modules/organizations"
  }

  assert {
    condition     = contains(keys(var.ou_names), "workloads")
    error_message = "Default OU structure must include a 'workloads' OU."
  }
}

# ---------------------------------------------------------------------------
# Service access principals — essential integrations must be present
# ---------------------------------------------------------------------------
run "cloudtrail_service_access_enabled" {
  command = plan

  module {
    source = "./modules/organizations"
  }

  assert {
    condition     = contains(var.aws_service_access_principals, "cloudtrail.amazonaws.com")
    error_message = "CloudTrail must be in the service access principals for centralized logging."
  }
}

run "sso_service_access_enabled" {
  command = plan

  module {
    source = "./modules/organizations"
  }

  assert {
    condition     = contains(var.aws_service_access_principals, "sso.amazonaws.com")
    error_message = "SSO must be in the service access principals for centralized identity."
  }
}

# ---------------------------------------------------------------------------
# Policy types — SCP must be enabled
# ---------------------------------------------------------------------------
run "scp_policy_type_enabled" {
  command = plan

  module {
    source = "./modules/organizations"
  }

  assert {
    condition     = contains(var.enabled_policy_types, "SERVICE_CONTROL_POLICY")
    error_message = "SERVICE_CONTROL_POLICY must be enabled for guardrails."
  }
}

# ---------------------------------------------------------------------------
# Custom OU configuration
# ---------------------------------------------------------------------------
run "custom_ou_names_accepted" {
  command = plan

  module {
    source = "./modules/organizations"
  }

  variables {
    ou_names = {
      prod    = "Production"
      staging = "Staging"
      dev     = "Development"
    }
  }

  assert {
    condition     = length(var.ou_names) == 3
    error_message = "Module should accept custom OU name maps."
  }
}

# ---------------------------------------------------------------------------
# Validation: feature_set rejects invalid values
# ---------------------------------------------------------------------------
run "invalid_feature_set_rejected" {
  command = plan

  module {
    source = "./modules/organizations"
  }

  variables {
    feature_set = "INVALID"
  }

  expect_failures = [
    var.feature_set,
  ]
}
