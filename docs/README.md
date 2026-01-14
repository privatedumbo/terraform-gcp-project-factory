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

## Documentation Index

| Guide | Description |
|-------|-------------|
| [Bootstrap](bootstrap.md) | One-time seed project setup |
| [Usage](usage.md) | Configuration, commands, and examples |

## Prerequisites

- [Terraform](https://terraform.io) >= 1.5
- [gcloud CLI](https://cloud.google.com/sdk) installed and authenticated
- GCP billing account with Billing Account Administrator role

## Cost

| Component | Cost |
|-----------|------|
| Seed project | Free (just state storage) |
| Child projects | Free (project itself) |
| State buckets | ~$0.02/GB/month |
| Billing budgets | Free |

Actual costs depend on what you deploy *in* the child projects.

