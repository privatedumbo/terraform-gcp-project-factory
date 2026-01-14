# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------

variable "billing_account" {
  description = "Default billing account ID for projects (e.g., '010A3E-959CD3-D47E70')"
  type        = string
}

variable "seed_service_account" {
  description = "Email of the seed service account running this Terraform"
  type        = string
}

# ------------------------------------------------------------------------------
# Optional Variables
# ------------------------------------------------------------------------------

variable "default_region" {
  description = "Default region for resources (us-central1 is free tier eligible)"
  type        = string
  default     = "us-central1"
}

variable "monthly_budget_usd" {
  description = "Monthly budget in USD. Set to 0 to disable budget alerts."
  type        = number
  default     = 25
}

# ------------------------------------------------------------------------------
# Projects Configuration
# ------------------------------------------------------------------------------

variable "projects" {
  description = <<-EOT
    Map of GCP projects to create. The key becomes the project ID.
    
    Each project can specify:
      - display_name: Human-readable name (defaults to project ID)
      - billing_account: Override the default billing account
      - apis: List of APIs to enable
      - iam: Map of IAM bindings (member -> list of roles)
      - github_repository: GitHub repo for OIDC (e.g., 'owner/repo')
  EOT

  type = map(object({
    display_name      = optional(string)
    billing_account   = optional(string)
    apis              = optional(list(string), [])
    iam               = optional(map(list(string)), {})
    github_repository = optional(string)
  }))
}

