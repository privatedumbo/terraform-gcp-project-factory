# Bootstrap: Seed Project Setup

Before Terraform can create GCP projects, you need a **seed project**. This is a one-time manual setup.

## What You're Creating

- A GCP project to run Terraform from
- A service account with permissions to create projects
- A GCS bucket for Terraform state

## Prerequisites

- `gcloud` CLI authenticated (`gcloud auth login`)
- A GCP billing account ID (find it: `gcloud billing accounts list`)
- Billing Account Administrator role on your billing account

---

## Step 1: Set Variables

```bash
# Choose a unique project ID
export SEED_PROJECT_ID="my-terraform-seed"

# Your billing account ID
export BILLING_ACCOUNT="XXXXXX-XXXXXX-XXXXXX"
```

## Step 2: Create the Seed Project

```bash
gcloud projects create $SEED_PROJECT_ID --name="Terraform Seed"

gcloud billing projects link $SEED_PROJECT_ID \
  --billing-account=$BILLING_ACCOUNT
```

## Step 3: Enable Required APIs

```bash
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  iam.googleapis.com \
  storage.googleapis.com \
  billingbudgets.googleapis.com \
  iamcredentials.googleapis.com \
  --project=$SEED_PROJECT_ID
```

## Step 4: Create Service Account

```bash
gcloud iam service-accounts create terraform-sa \
  --project=$SEED_PROJECT_ID \
  --display-name="Terraform Service Account"

gcloud billing accounts add-iam-policy-binding $BILLING_ACCOUNT \
  --member="serviceAccount:terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/billing.user"
```

## Step 5: Create State Bucket

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

## Step 6: Configure Terraform Backend (Optional)

After completing the above, uncomment and edit the backend in `projects/providers.tf`:

```hcl
backend "gcs" {
  bucket = "my-terraform-seed-tfstate"
  prefix = "terraform/projects"
}
```

---

## All Commands (Copy-Paste Block)

```bash
# Set these first
export SEED_PROJECT_ID="my-terraform-seed"
export BILLING_ACCOUNT="XXXXXX-XXXXXX-XXXXXX"

# Run all setup commands
gcloud projects create $SEED_PROJECT_ID --name="Terraform Seed"

gcloud billing projects link $SEED_PROJECT_ID \
  --billing-account=$BILLING_ACCOUNT

gcloud services enable \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  iam.googleapis.com \
  storage.googleapis.com \
  billingbudgets.googleapis.com \
  iamcredentials.googleapis.com \
  --project=$SEED_PROJECT_ID

gcloud iam service-accounts create terraform-sa \
  --project=$SEED_PROJECT_ID \
  --display-name="Terraform Service Account"

gcloud billing accounts add-iam-policy-binding $BILLING_ACCOUNT \
  --member="serviceAccount:terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/billing.user"

gcloud storage buckets create gs://${SEED_PROJECT_ID}-tfstate \
  --project=$SEED_PROJECT_ID \
  --location=us-central1 \
  --uniform-bucket-level-access

gcloud storage buckets add-iam-policy-binding gs://${SEED_PROJECT_ID}-tfstate \
  --member="serviceAccount:terraform-sa@${SEED_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

---

## Next Steps

Continue to [Usage Guide](usage.md) to configure and create your projects.

