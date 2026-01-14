# Bootstrap: Seed Project Setup

Before Terraform can create GCP projects, you need a **seed project**. This is a one-time manual setup.

## What You're Creating

- A GCP project to run Terraform from
- A service account with permissions to create and manage projects
- A GCS bucket for Terraform state

---

## Prerequisites

### Required Tools

```bash
# Verify gcloud is installed
gcloud version

# If not installed: https://cloud.google.com/sdk/docs/install
```

### Required Access

- A GCP account (free tier works)
- A billing account ID where you have **Billing Account User** role
  - Find yours: `gcloud billing accounts list`
  - If empty, [create a billing account](https://console.cloud.google.com/billing)

---

## Step 1: Authenticate

```bash
# Login to GCP (opens browser)
gcloud auth login

# Verify you're logged in
gcloud auth list
```

---

## Step 2: Set Variables

```bash
# Choose a globally unique project ID (lowercase, hyphens ok)
export SEED_PROJECT_ID="my-terraform-seed-123"

# Your billing account ID (from Step 1 or gcloud billing accounts list)
export BILLING_ACCOUNT="XXXXXX-XXXXXX-XXXXXX"

# Your email (for service account impersonation)
export USER_EMAIL=$(gcloud config get-value account)
```

---

## Step 3: Create the Seed Project

```bash
# Create the project
gcloud projects create $SEED_PROJECT_ID \
  --name="Terraform Seed"

# Link billing
gcloud billing projects link $SEED_PROJECT_ID \
  --billing-account=$BILLING_ACCOUNT

# Set as default project
gcloud config set project $SEED_PROJECT_ID
```

---

## Step 4: Enable Required APIs

```bash
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  iam.googleapis.com \
  serviceusage.googleapis.com \
  storage.googleapis.com \
  billingbudgets.googleapis.com \
  iamcredentials.googleapis.com \
  --project=$SEED_PROJECT_ID
```

> ⏱️ API enablement can take 30-60 seconds to propagate.

---

## Step 5: Create Service Account

```bash
# Create the service account
gcloud iam service-accounts create terraform-sa \
  --project=$SEED_PROJECT_ID \
  --display-name="Terraform Service Account"

# Grant billing.user so it can link billing to new projects
gcloud billing accounts add-iam-policy-binding $BILLING_ACCOUNT \
  --member="serviceAccount:terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/billing.user"

# Grant YOUR USER permission to impersonate this SA
gcloud iam service-accounts add-iam-policy-binding \
  terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com \
  --member="user:${USER_EMAIL}" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project=$SEED_PROJECT_ID
```

> ⏱️ IAM changes can take 60 seconds to propagate.

---

## Step 6: Create State Bucket

```bash
gcloud storage buckets create gs://${SEED_PROJECT_ID}-tfstate \
  --project=$SEED_PROJECT_ID \
  --location=us-central1 \
  --uniform-bucket-level-access

gcloud storage buckets add-iam-policy-binding gs://${SEED_PROJECT_ID}-tfstate \
  --member="serviceAccount:terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

---

## Step 7: Configure Application Default Credentials

Terraform uses [Application Default Credentials (ADC)](https://cloud.google.com/docs/authentication/application-default-credentials) to authenticate.

```bash
# Login for ADC (opens browser, separate from gcloud auth login)
gcloud auth application-default login

# Set quota project (required for billing budget API)
gcloud auth application-default set-quota-project $SEED_PROJECT_ID
```

---

## Step 8: Verify Setup

```bash
echo "=== Verification ==="

# Check project exists
gcloud projects describe $SEED_PROJECT_ID --format="value(projectId)"

# Check billing is linked
gcloud billing projects describe $SEED_PROJECT_ID --format="value(billingAccountName)"

# Check service account exists
gcloud iam service-accounts describe \
  terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com \
  --format="value(email)"

# Check state bucket exists
gcloud storage buckets describe gs://${SEED_PROJECT_ID}-tfstate \
  --format="value(name)"

# Check ADC is configured
gcloud auth application-default print-access-token > /dev/null && echo "ADC: OK"

echo "=== All checks passed ==="
```

---

## All Commands (Copy-Paste Block)

```bash
#!/bin/bash
set -e

# ============================================================================
# CONFIGURE THESE
# ============================================================================
export SEED_PROJECT_ID="my-terraform-seed"
export BILLING_ACCOUNT="XXXXXX-XXXXXX-XXXXXX"

# ============================================================================
# AUTHENTICATE
# ============================================================================
gcloud auth login
export USER_EMAIL=$(gcloud config get-value account)

# ============================================================================
# CREATE SEED PROJECT
# ============================================================================
gcloud projects create $SEED_PROJECT_ID --name="Terraform Seed"

gcloud billing projects link $SEED_PROJECT_ID \
  --billing-account=$BILLING_ACCOUNT

gcloud config set project $SEED_PROJECT_ID

# ============================================================================
# ENABLE APIS
# ============================================================================
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  iam.googleapis.com \
  serviceusage.googleapis.com \
  storage.googleapis.com \
  billingbudgets.googleapis.com \
  iamcredentials.googleapis.com \
  --project=$SEED_PROJECT_ID

# ============================================================================
# CREATE SERVICE ACCOUNT
# ============================================================================
gcloud iam service-accounts create terraform-sa \
  --project=$SEED_PROJECT_ID \
  --display-name="Terraform Service Account"

gcloud billing accounts add-iam-policy-binding $BILLING_ACCOUNT \
  --member="serviceAccount:terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/billing.user"

gcloud iam service-accounts add-iam-policy-binding \
  terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com \
  --member="user:${USER_EMAIL}" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project=$SEED_PROJECT_ID

# ============================================================================
# CREATE STATE BUCKET
# ============================================================================
gcloud storage buckets create gs://${SEED_PROJECT_ID}-tfstate \
  --project=$SEED_PROJECT_ID \
  --location=us-central1 \
  --uniform-bucket-level-access

gcloud storage buckets add-iam-policy-binding gs://${SEED_PROJECT_ID}-tfstate \
  --member="serviceAccount:terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# ============================================================================
# CONFIGURE ADC
# ============================================================================
gcloud auth application-default login
gcloud auth application-default set-quota-project $SEED_PROJECT_ID

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. cd projects"
echo "  2. cp terraform.tfvars.example terraform.tfvars"
echo "  3. Edit terraform.tfvars with:"
echo "     - billing_account = \"$BILLING_ACCOUNT\""
echo "     - seed_service_account = \"terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com\""
echo "  4. terraform init && terraform apply"
```

---

## Configure Terraform Backend (Optional)

After completing the above, uncomment and edit the backend in `projects/providers.tf`:

```hcl
backend "gcs" {
  bucket = "my-terraform-seed-tfstate"  # Use your SEED_PROJECT_ID
  prefix = "terraform/projects"
}
```

And uncomment the provider project settings:

```hcl
provider "google" {
  project               = "my-terraform-seed"  # Use your SEED_PROJECT_ID
  billing_project       = "my-terraform-seed"
  user_project_override = true
}
```

---

## Troubleshooting

### "The billing account is not authorized on this project"

Your user doesn't have billing permissions. Ask your billing admin to grant you `roles/billing.user` on the billing account:

```bash
gcloud billing accounts add-iam-policy-binding $BILLING_ACCOUNT \
  --member="user:your-email@example.com" \
  --role="roles/billing.user"
```

### "Project ID already exists"

Project IDs are globally unique. Choose a different `SEED_PROJECT_ID`:

```bash
export SEED_PROJECT_ID="my-terraform-seed-$(date +%s)"
```

### "IAM policy modification failed"

IAM changes can take up to 60 seconds to propagate. Wait and retry:

```bash
sleep 60
# Then retry the command
```

### "Request had insufficient authentication scopes"

Re-run the ADC login with the quota project:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project $SEED_PROJECT_ID
```

---

## Next Steps

Continue to [Usage Guide](usage.md) to configure and create your projects.
