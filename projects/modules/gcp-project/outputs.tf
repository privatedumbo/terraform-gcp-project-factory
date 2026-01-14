# ------------------------------------------------------------------------------
# Project Outputs
# ------------------------------------------------------------------------------

output "project_id" {
  description = "The created project ID"
  value       = google_project.this.project_id
}

output "project_number" {
  description = "The created project number"
  value       = google_project.this.number
}

# ------------------------------------------------------------------------------
# Service Account Outputs
# ------------------------------------------------------------------------------

output "service_account_email" {
  description = "Email of the Terraform service account"
  value       = google_service_account.terraform.email
}

# ------------------------------------------------------------------------------
# State Bucket Outputs
# ------------------------------------------------------------------------------

output "state_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = google_storage_bucket.tfstate.name
}

# ------------------------------------------------------------------------------
# GitHub Actions OIDC Outputs
# ------------------------------------------------------------------------------

output "workload_identity_provider" {
  description = "Full resource name of the Workload Identity Provider (for GitHub Actions)"
  value       = one(google_iam_workload_identity_pool_provider.github[*].name)
}

