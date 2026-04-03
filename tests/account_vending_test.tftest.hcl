###############################################################################
# Tests — Account Vending Module
# Validates account creation parameters, email format, and baseline defaults.
###############################################################################

# ---------------------------------------------------------------------------
# Valid account configuration — single account with all required fields
# ---------------------------------------------------------------------------
run "single_account_valid" {
  command = plan

  module {
    source = "./modules/account-vending"
  }

  variables {
    accounts = {
      dev-account = {
        email = "aws-dev@example.com"
        ou_id = "ou-abc1-workloads0"
      }
    }
  }

  assert {
    condition     = length(var.accounts) == 1
    error_message = "Module should accept a single account definition."
  }
}

# ---------------------------------------------------------------------------
# Multiple accounts — batch account creation
# ---------------------------------------------------------------------------
run "multiple_accounts_valid" {
  command = plan

  module {
    source = "./modules/account-vending"
  }

  variables {
    accounts = {
      dev = {
        email = "aws-dev@example.com"
        ou_id = "ou-abc1-workloads0"
      }
      staging = {
        email = "aws-staging@example.com"
        ou_id = "ou-abc1-workloads0"
      }
      production = {
        email = "aws-prod@example.com"
        ou_id = "ou-abc1-workloads0"
      }
    }
  }

  assert {
    condition     = length(var.accounts) == 3
    error_message = "Module should accept multiple account definitions."
  }
}

# ---------------------------------------------------------------------------
# Default baseline settings — IAM users, Config, and GuardDuty enabled
# ---------------------------------------------------------------------------
run "baseline_defaults_enabled" {
  command = plan

  module {
    source = "./modules/account-vending"
  }

  variables {
    accounts = {
      test-account = {
        email = "aws-test@example.com"
        ou_id = "ou-abc1-sandbox000"
      }
    }
  }

  assert {
    condition     = var.accounts["test-account"].allow_iam_users == true
    error_message = "IAM user access should be enabled by default."
  }
}

run "config_enabled_by_default" {
  command = plan

  module {
    source = "./modules/account-vending"
  }

  variables {
    accounts = {
      test-account = {
        email = "aws-test@example.com"
        ou_id = "ou-abc1-sandbox000"
      }
    }
  }

  assert {
    condition     = var.accounts["test-account"].enable_config == true
    error_message = "AWS Config should be enabled by default for compliance."
  }
}

run "guardduty_enabled_by_default" {
  command = plan

  module {
    source = "./modules/account-vending"
  }

  variables {
    accounts = {
      test-account = {
        email = "aws-test@example.com"
        ou_id = "ou-abc1-sandbox000"
      }
    }
  }

  assert {
    condition     = var.accounts["test-account"].enable_guardduty == true
    error_message = "GuardDuty should be enabled by default for threat detection."
  }
}

# ---------------------------------------------------------------------------
# Close on deletion — disabled by default for safety
# ---------------------------------------------------------------------------
run "close_on_deletion_disabled_by_default" {
  command = plan

  module {
    source = "./modules/account-vending"
  }

  variables {
    accounts = {
      test-account = {
        email = "aws-test@example.com"
        ou_id = "ou-abc1-sandbox000"
      }
    }
  }

  assert {
    condition     = var.accounts["test-account"].close_on_deletion == false
    error_message = "close_on_deletion should be false by default to prevent accidental account closure."
  }
}

# ---------------------------------------------------------------------------
# Custom baseline overrides
# ---------------------------------------------------------------------------
run "baseline_overrides_accepted" {
  command = plan

  module {
    source = "./modules/account-vending"
  }

  variables {
    accounts = {
      sandbox-account = {
        email             = "aws-sandbox@example.com"
        ou_id             = "ou-abc1-sandbox000"
        allow_iam_users   = false
        enable_config     = false
        enable_guardduty  = false
        close_on_deletion = true
        tags = {
          Environment = "sandbox"
        }
      }
    }
  }

  assert {
    condition     = var.accounts["sandbox-account"].allow_iam_users == false
    error_message = "Module should accept IAM user override."
  }
}

# ---------------------------------------------------------------------------
# Validation: invalid email format rejected
# ---------------------------------------------------------------------------
run "invalid_email_rejected" {
  command = plan

  module {
    source = "./modules/account-vending"
  }

  variables {
    accounts = {
      bad-account = {
        email = "not-an-email"
        ou_id = "ou-abc1-workloads0"
      }
    }
  }

  expect_failures = [
    var.accounts,
  ]
}

# ---------------------------------------------------------------------------
# Default IAM alias prefix
# ---------------------------------------------------------------------------
run "default_iam_alias_prefix" {
  command = plan

  module {
    source = "./modules/account-vending"
  }

  variables {
    accounts = {
      test-account = {
        email = "aws-test@example.com"
        ou_id = "ou-abc1-sandbox000"
      }
    }
  }

  assert {
    condition     = var.baseline_iam_alias_prefix == "org"
    error_message = "Default IAM alias prefix should be 'org'."
  }
}
