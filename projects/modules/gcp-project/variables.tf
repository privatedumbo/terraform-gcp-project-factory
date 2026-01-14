# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID to create (must be globally unique)"
  type        = string
}

variable "display_name" {
  description = "Human-readable display name for the project"
  type        = string
}

variable "billing_account" {
  description = "Billing account ID to associate with the project"
  type        = string
}

variable "seed_service_account" {
  description = "Email of the seed service account (granted Owner role)"
  type        = string
}

# ------------------------------------------------------------------------------
# Optional Variables
# ------------------------------------------------------------------------------

variable "region" {
  description = "Region for the state bucket"
  type        = string
  default     = "us-central1"
}

variable "activate_apis" {
  description = "List of APIs to enable in the project"
  type        = list(string)
  default     = []
}

variable "project_iam" {
  description = "IAM bindings: map of member -> list of roles"
  type        = map(list(string))
  default     = {}
}

variable "github_repository" {
  description = "GitHub repository for OIDC (e.g., 'owner/repo'). Set to null to disable."
  type        = string
  default     = null
}

