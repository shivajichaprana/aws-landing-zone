###############################################################################
# Tests — Service Control Policies Module
# Validates SCP variable defaults, region restrictions, and toggle behavior.
###############################################################################

# ---------------------------------------------------------------------------
# Default configuration — all guardrails enabled by default
# ---------------------------------------------------------------------------
run "deny_root_enabled_by_default" {
  command = plan

  module {
    source = "./modules/scp"
  }

  variables {
    target_ou_ids = {
      security = "ou-abc1-security00"
      workloads = "ou-abc1-workloads0"
    }
  }

  assert {
    condition     = var.enable_deny_root_account == true
    error_message = "Deny root account SCP should be enabled by default."
  }
}

run "deny_leave_org_enabled_by_default" {
  command = plan

  module {
    source = "./modules/scp"
  }

  variables {
    target_ou_ids = {
      security = "ou-abc1-security00"
    }
  }

  assert {
    condition     = var.enable_deny_leave_org == true
    error_message = "Deny leave organization SCP should be enabled by default."
  }
}

run "restrict_regions_enabled_by_default" {
  command = plan

  module {
    source = "./modules/scp"
  }

  variables {
    target_ou_ids = {
      workloads = "ou-abc1-workloads0"
    }
  }

  assert {
    condition     = var.enable_restrict_regions == true
    error_message = "Region restriction SCP should be enabled by default."
  }
}

run "require_encryption_enabled_by_default" {
  command = plan

  module {
    source = "./modules/scp"
  }

  variables {
    target_ou_ids = {
      workloads = "ou-abc1-workloads0"
    }
  }

  assert {
    condition     = var.enable_require_encryption == true
    error_message = "Require encryption SCP should be enabled by default."
  }
}

# ---------------------------------------------------------------------------
# Allowed regions — defaults and custom values
# ---------------------------------------------------------------------------
run "default_allowed_regions_include_us_east_1" {
  command = plan

  module {
    source = "./modules/scp"
  }

  variables {
    target_ou_ids = {
      workloads = "ou-abc1-workloads0"
    }
  }

  assert {
    condition     = contains(var.allowed_regions, "us-east-1")
    error_message = "us-east-1 must be in the default allowed regions (required for global services)."
  }
}

run "custom_allowed_regions_accepted" {
  command = plan

  module {
    source = "./modules/scp"
  }

  variables {
    target_ou_ids = {
      workloads = "ou-abc1-workloads0"
    }
    allowed_regions = ["eu-central-1", "eu-west-1"]
  }

  assert {
    condition     = length(var.allowed_regions) == 2
    error_message = "Module should accept custom allowed regions list."
  }
}

# ---------------------------------------------------------------------------
# Validation: target_ou_ids must not be empty
# ---------------------------------------------------------------------------
run "empty_target_ou_ids_rejected" {
  command = plan

  module {
    source = "./modules/scp"
  }

  variables {
    target_ou_ids = {}
  }

  expect_failures = [
    var.target_ou_ids,
  ]
}

# ---------------------------------------------------------------------------
# Validation: allowed_regions must not be empty
# ---------------------------------------------------------------------------
run "empty_allowed_regions_rejected" {
  command = plan

  module {
    source = "./modules/scp"
  }

  variables {
    target_ou_ids = {
      workloads = "ou-abc1-workloads0"
    }
    allowed_regions = []
  }

  expect_failures = [
    var.allowed_regions,
  ]
}

# ---------------------------------------------------------------------------
# Toggle behavior — individual SCPs can be disabled
# ---------------------------------------------------------------------------
run "all_scps_can_be_disabled" {
  command = plan

  module {
    source = "./modules/scp"
  }

  variables {
    target_ou_ids = {
      workloads = "ou-abc1-workloads0"
    }
    enable_deny_root_account  = false
    enable_deny_leave_org     = false
    enable_restrict_regions   = false
    enable_require_encryption = false
  }

  assert {
    condition     = var.enable_deny_root_account == false
    error_message = "Should be able to disable deny root account SCP."
  }
}
