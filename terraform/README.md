# Terraform Infrastructure

This directory contains Terraform configurations for deploying the Report Card AI Assistant on Google Cloud Platform (GCP).

## Infrastructure Components

- **Cloud Run**: Containerized application deployment
- **Cloud Storage**: File storage for PDFs and indices
- **Vertex AI**: Vector search and embeddings
- **Firestore**: Chat history and metadata storage
- **Cloud Build**: CI/CD pipeline
- **IAM**: Service account and permissions

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Plan the infrastructure:
   ```bash
   terraform plan
   ```

3. Apply the changes:
   ```bash
   terraform apply
   ```

## Security Note

This is a showcase version of the infrastructure. In production, you should:
- Use proper secret management
- Implement network security rules
- Configure proper IAM roles
- Set up monitoring and logging
- Use private networking where appropriate

# ReportCard RAG Chatbot - Terraform Deployment

This directory contains Terraform configuration for deploying all required GCP resources for the ReportCard RAG Chatbot application.

## Resources Provisioned

- GCS Buckets (for uploads and indices)
- Firestore Database
- Secret Manager Secrets
- Vertex AI Vector Search Index and Endpoint
- Service Account with proper IAM permissions
- Conditional Cloud Run service deployment

## Important Deployment Timeline Notes

**Please be aware of these important timeframes during deployment:**

- Vertex AI Vector Search Index creation: **~1 minute**
- Vertex AI Vector Search Endpoint creation: **~3-5 minutes**
- Deployment of index to endpoint: **~20-30 minutes**

The LlamaIndex integration expects that both the Vector Search index and its deployment to the endpoint are fully complete before use.

## Deployment Instructions

### Prerequisites

1. Google Cloud SDK installed and configured
2. Terraform >= 1.0.0 installed
3. GCP project with billing enabled
4. `.env` file at the root of the project with API keys

### Step 1: Initialize Terraform

Before the first deployment, create a GCS bucket for Terraform state:

```bash
# Create Terraform state bucket (one-time setup)
gcloud storage buckets create gs://reportcard-rag-tf-state --location=us-central1
```

Initialize Terraform:

```bash
cd terraform
terraform init
```

### Step 2: Plan the Deployment

```bash
terraform plan -out=tfplan
```

Review the planned changes carefully.

### Step 3: Apply Configuration

```bash
terraform apply tfplan
```

This will create all the infrastructure. **Note that complete deployment may take up to 30-45 minutes** due to Vertex AI Vector Search deployment times.

### Step 4: Populate Secrets

After the infrastructure is created, populate the secrets with values from your `.env` file:

```bash
chmod +x setup_secrets.sh
./setup_secrets.sh
```

### Step 5: Verify Deployment

Use the `check_gcp_services.sh` script from the project root to verify all resources:

```bash
cd ..
./check_gcp_services.sh
```

## Cloud Run Deployment (Optional)

By default, the Cloud Run service is not deployed. To deploy it:

```bash
# First build and push the container image
# Then enable Cloud Run deployment
terraform apply -var="enable_cloud_run=true" -var="container_image=gcr.io/reportcard-rag/reportcard-chatbot:latest"
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning:** This will delete all resources including stored data in GCS and Firestore. 