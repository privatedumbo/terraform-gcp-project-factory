# ------------------------------------------------------------------------------
# GCP Project Module
# ------------------------------------------------------------------------------
# Creates a standalone GCP project with:
#   - Terraform service account (Owner role)
#   - Terraform state bucket (versioned)
#   - GitHub Actions OIDC (optional)
#   - Custom API enablement
#   - Custom IAM bindings

locals {
  # APIs that must be present on every project
  mandatory_apis = [
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "cloudbilling.googleapis.com",
    "iamcredentials.googleapis.com",
  ]

  # Merge mandatory APIs with user-provided APIs, remove duplicates
  final_api_list = distinct(concat(local.mandatory_apis, var.activate_apis))
}

# ------------------------------------------------------------------------------
# Project
# ------------------------------------------------------------------------------

resource "google_project" "this" {
  name            = var.display_name
  project_id      = var.project_id
  billing_account = var.billing_account

  # No org_id or folder_id = standalone project
}

resource "google_project_service" "apis" {
  for_each = toset(local.final_api_list)

  project = google_project.this.project_id
  service = each.value

  disable_on_destroy = false
}

# ------------------------------------------------------------------------------
# Terraform Service Account
# ------------------------------------------------------------------------------

resource "google_service_account" "terraform" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
  project      = google_project.this.project_id

  depends_on = [google_project_service.apis]
}

# Grant Owner role to the project's terraform SA
resource "google_project_iam_member" "terraform_owner" {
  project = google_project.this.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

# Grant Owner role to the seed SA (so it can continue managing the project)
resource "google_project_iam_member" "seed_owner" {
  project = google_project.this.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${var.seed_service_account}"
}

# ------------------------------------------------------------------------------
# Terraform State Bucket
# ------------------------------------------------------------------------------

resource "google_storage_bucket" "tfstate" {
  name          = "${google_project.this.project_id}-tfstate"
  project       = google_project.this.project_id
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.apis]
}

resource "google_storage_bucket_iam_member" "terraform_state_admin" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.terraform.email}"
}

# ------------------------------------------------------------------------------
# Custom IAM Bindings
# ------------------------------------------------------------------------------

locals {
  # Flatten project_iam map into a list of { member, role } objects
  # Input:  { "user:a@b.com" = ["roles/owner", "roles/editor"] }
  # Output: [ { member = "user:a@b.com", role = "roles/owner" }, ... ]
  iam_bindings = flatten([
    for member, roles in var.project_iam : [
      for role in roles : {
        member = member
        role   = role
      }
    ]
  ])
}

resource "google_project_iam_member" "custom" {
  for_each = {
    for binding in local.iam_bindings :
    "${binding.role}--${binding.member}" => binding
  }

  project = google_project.this.project_id
  role    = each.value.role
  member  = each.value.member
}

# ------------------------------------------------------------------------------
# GitHub Actions OIDC (Workload Identity Federation)
# ------------------------------------------------------------------------------

resource "google_iam_workload_identity_pool" "github" {
  count = var.github_repository != null ? 1 : 0

  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions"
  project                   = google_project.this.project_id

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count = var.github_repository != null ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC provider for GitHub Actions"
  project                            = google_project.this.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  # Only allow tokens from the specified repository
  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_workload_identity" {
  count = var.github_repository != null ? 1 : 0

  service_account_id = google_service_account.terraform.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[0].name}/attribute.repository/${var.github_repository}"
}

