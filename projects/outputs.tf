# ------------------------------------------------------------------------------
# Project Outputs
# ------------------------------------------------------------------------------

output "projects" {
  description = "Details of all created projects"
  value = {
    for key, mod in module.gcp_project : key => {
      project_id                 = mod.project_id
      project_number             = mod.project_number
      service_account_email      = mod.service_account_email
      state_bucket_name          = mod.state_bucket_name
      workload_identity_provider = mod.workload_identity_provider
    }
  }
}

output "budget_name" {
  description = "Name of the billing budget (if created)"
  value       = one(google_billing_budget.monthly_budget[*].name)
}

# ------------------------------------------------------------------------------
# Convenience Outputs for CI/CD Setup
# ------------------------------------------------------------------------------

output "github_actions_setup" {
  description = "Values needed to configure GitHub Actions environments"
  value = {
    for key, mod in module.gcp_project : key => {
      GCP_PROJECT_ID                 = mod.project_id
      GCP_WORKLOAD_IDENTITY_PROVIDER = mod.workload_identity_provider
      GCP_SERVICE_ACCOUNT            = mod.service_account_email
    } if mod.workload_identity_provider != null
  }
}

