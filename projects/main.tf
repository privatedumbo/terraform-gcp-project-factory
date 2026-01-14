# ------------------------------------------------------------------------------
# GCP Project Factory
# ------------------------------------------------------------------------------
# Creates standalone GCP projects without requiring a GCP Organization.
# Each project gets:
#   - A Terraform service account with Owner role
#   - A GCS bucket for Terraform state
#   - GitHub Actions OIDC for CI/CD (optional)
#   - User-specified APIs enabled
#   - Custom IAM bindings

module "gcp_project" {
  source   = "./modules/gcp-project"
  for_each = var.projects

  project_id      = each.key
  display_name    = coalesce(each.value.display_name, each.key)
  billing_account = coalesce(each.value.billing_account, var.billing_account)

  activate_apis        = each.value.apis
  project_iam          = each.value.iam
  github_repository    = each.value.github_repository
  region               = var.default_region
  seed_service_account = var.seed_service_account
}

# ------------------------------------------------------------------------------
# Billing Budget
# ------------------------------------------------------------------------------
# Creates a budget alert covering all managed projects.
# Alerts at 50%, 90%, and 100% of the monthly budget.

resource "google_billing_budget" "monthly_budget" {
  count = var.monthly_budget_usd > 0 ? 1 : 0

  billing_account = var.billing_account
  display_name    = "Monthly Budget Alert"

  budget_filter {
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.9
  }

  threshold_rules {
    threshold_percent = 1.0
  }
}

