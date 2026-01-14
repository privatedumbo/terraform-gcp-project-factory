terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }

  # Uncomment after creating the seed project (see bootstrap/README.md)
  # backend "gcs" {
  #   bucket = "your-seed-project-tfstate"
  #   prefix = "terraform/projects"
  # }
}

provider "google" {
  # Uncomment after creating the seed project
  # project               = "your-seed-project"
  # billing_project       = "your-seed-project"
  # user_project_override = true

  # Authentication is sourced from:
  #   - GOOGLE_APPLICATION_CREDENTIALS env var, or
  #   - gcloud auth application-default login
}

