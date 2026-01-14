# Documentation

## What This Template Does

This Terraform template implements the "project of projects" pattern for GCP:

1. You create a **seed project** manually (one-time setup)
2. Terraform uses the seed project to create and manage **child projects**
3. Each child project is fully configured for independent Terraform workflows

### What Each Child Project Gets

| Resource | Purpose |
|----------|---------|
| Terraform Service Account | Owner role for managing the project |
| State Bucket | Versioned GCS bucket for Terraform state |
| GitHub OIDC | Keyless authentication for GitHub Actions |
| Enabled APIs | Your specified GCP APIs |
| IAM Bindings | Your specified access grants |

### Why This Pattern?

- **Isolation** — Each project has its own billing, quotas, and IAM
- **Autonomy** — Teams can manage their project independently
- **Consistency** — All projects follow the same baseline configuration
- **Security** — Keyless CI/CD via Workload Identity Federation

---

## Getting Started Checklist

Here's the complete journey from clone to running Terraform:

### Prerequisites

| Requirement | How to Check |
|-------------|--------------|
| Terraform ≥ 1.5 | `terraform version` |
| gcloud CLI | `gcloud version` |
| GCP account | `gcloud auth list` |
| Billing account | `gcloud billing accounts list` |

### Step-by-Step Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. AUTHENTICATE                                                 │
│    gcloud auth login                                            │
│    gcloud auth application-default login                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. BOOTSTRAP SEED PROJECT (one-time)                            │
│    See: docs/bootstrap.md                                       │
│    • Create GCP project                                         │
│    • Enable APIs                                                │
│    • Create service account                                     │
│    • Create state bucket                                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. CONFIGURE                                                    │
│    cd projects                                                  │
│    cp terraform.tfvars.example terraform.tfvars                 │
│    # Edit terraform.tfvars                                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. RUN TERRAFORM                                                │
│    terraform init                                               │
│    terraform plan                                               │
│    terraform apply                                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. CONFIGURE CI/CD (optional)                                   │
│    terraform output github_actions_setup                        │
│    # Add values to GitHub repo settings                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Required gcloud Commands Summary

Here's every `gcloud` command you'll run, in order:

```bash
# Authentication (always needed)
gcloud auth login
gcloud auth application-default login

# Seed project setup (one-time, see bootstrap.md for details)
gcloud projects create $SEED_PROJECT_ID --name="Terraform Seed"
gcloud billing projects link $SEED_PROJECT_ID --billing-account=$BILLING_ACCOUNT
gcloud config set project $SEED_PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com cloudbilling.googleapis.com ...
gcloud iam service-accounts create terraform-sa ...
gcloud billing accounts add-iam-policy-binding ...
gcloud storage buckets create gs://${SEED_PROJECT_ID}-tfstate ...

# ADC configuration (needed for Terraform)
gcloud auth application-default set-quota-project $SEED_PROJECT_ID
```

See [Bootstrap Guide](bootstrap.md) for the complete copy-paste script.

---

## Documentation Index

| Guide | Description |
|-------|-------------|
| [Bootstrap](bootstrap.md) | One-time seed project setup with all gcloud commands |
| [Usage](usage.md) | Configuration, commands, and examples |

---

## Cost

| Component | Cost |
|-----------|------|
| Seed project | Free (just state storage) |
| Child projects | Free (project itself) |
| State buckets | ~$0.02/GB/month |
| Billing budgets | Free |

Actual costs depend on what you deploy *in* the child projects.
