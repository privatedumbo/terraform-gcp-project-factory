# Usage Guide

> **First time?** Complete the [Bootstrap Guide](bootstrap.md) before proceeding.

## Authentication

Before running Terraform, ensure you've authenticated with GCP:

```bash
# Check if already authenticated
gcloud auth application-default print-access-token > /dev/null && echo "ADC: OK"

# If not, authenticate (done during bootstrap)
gcloud auth application-default login
gcloud auth application-default set-quota-project YOUR_SEED_PROJECT_ID
```

---

## Configuration

### 1. Copy the Example File

```bash
cd projects
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit `terraform.tfvars`

```hcl
# Required
billing_account      = "XXXXXX-XXXXXX-XXXXXX"
seed_service_account = "terraform-sa@my-terraform-seed.iam.gserviceaccount.com"

# Optional
default_region     = "us-central1"  # Free tier eligible
monthly_budget_usd = 25             # 0 to disable

# Your projects
projects = {
  "myapp-dev" = {
    display_name      = "My App (Dev)"
    github_repository = "your-username/your-repo"
    apis = [
      "run.googleapis.com",
      "artifactregistry.googleapis.com",
    ]
  }
}
```

---

## Commands

### Initialize

```bash
cd projects
terraform init
```

### Preview Changes

```bash
terraform plan
```

### Apply Changes

```bash
terraform apply
```

### View Outputs

```bash
# All project details
terraform output projects

# GitHub Actions setup values
terraform output github_actions_setup
```

### Destroy (Careful!)

```bash
terraform destroy
```

---

## Project Configuration Options

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `display_name` | string | No | Human-readable name (defaults to project ID) |
| `billing_account` | string | No | Override default billing account |
| `apis` | list(string) | No | APIs to enable |
| `iam` | map(list(string)) | No | IAM bindings (member → roles) |
| `github_repository` | string | No | GitHub repo for OIDC (`owner/repo`) |

---

## Examples

### Basic Project (No CI/CD)

```hcl
projects = {
  "shared-infra" = {
    display_name = "Shared Infrastructure"
    apis = [
      "compute.googleapis.com",
      "container.googleapis.com",
    ]
  }
}
```

### Project with GitHub Actions

```hcl
projects = {
  "myapp-dev" = {
    github_repository = "myorg/myapp"
    apis = [
      "run.googleapis.com",
      "artifactregistry.googleapis.com",
      "secretmanager.googleapis.com",
    ]
  }
}
```

### Project with Custom IAM

```hcl
projects = {
  "team-project" = {
    display_name = "Team Project"
    iam = {
      "user:alice@example.com"   = ["roles/owner"]
      "group:devs@example.com"   = ["roles/editor"]
      "user:bob@example.com"     = ["roles/viewer"]
    }
  }
}
```

### Multiple Environments

```hcl
projects = {
  "myapp-dev" = {
    display_name      = "My App (Dev)"
    github_repository = "myorg/myapp"
    apis              = ["run.googleapis.com"]
  }

  "myapp-staging" = {
    display_name      = "My App (Staging)"
    github_repository = "myorg/myapp"
    apis              = ["run.googleapis.com"]
  }

  "myapp-prod" = {
    display_name      = "My App (Prod)"
    github_repository = "myorg/myapp"
    apis              = ["run.googleapis.com", "sqladmin.googleapis.com"]
    iam = {
      "group:oncall@example.com" = ["roles/viewer"]
    }
  }
}
```

---

## GitHub Actions Setup

For each project with `github_repository` configured:

### 1. Get the Values

```bash
terraform output github_actions_setup
```

Output:

```hcl
{
  "myapp-dev" = {
    GCP_PROJECT_ID                 = "myapp-dev"
    GCP_SERVICE_ACCOUNT            = "terraform-sa@myapp-dev.iam..."
    GCP_WORKLOAD_IDENTITY_PROVIDER = "projects/123.../providers/github-provider"
  }
}
```

### 2. Create GitHub Environment

1. Go to **Settings → Environments** in your GitHub repo
2. Create an environment (e.g., `dev`)
3. Add these variables:

| Variable | Value |
|----------|-------|
| `GCP_PROJECT_ID` | From output |
| `GCP_SERVICE_ACCOUNT` | From output |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | From output |

### 3. Use in Workflow

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: dev
    
    permissions:
      contents: read
      id-token: write  # Required for OIDC
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
      
      - uses: google-github-actions/setup-gcloud@v2
      
      - run: gcloud projects describe ${{ vars.GCP_PROJECT_ID }}
```

---

## Troubleshooting

### "Permission denied" on billing

Your user needs **Billing Account Administrator** role on the billing account.

```bash
gcloud billing accounts get-iam-policy XXXXXX-XXXXXX-XXXXXX
```

### "API not enabled" errors

The seed project needs these APIs enabled:

```bash
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  --project=YOUR_SEED_PROJECT_ID
```

### GitHub Actions auth fails

1. Check the repository name matches exactly (case-sensitive)
2. Ensure `id-token: write` permission is set in the workflow
3. Verify the environment variables are set correctly

