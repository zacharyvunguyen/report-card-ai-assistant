# Report Card RAG Chatbot - Deployment Guide

## Prerequisites
- Google Cloud Platform account with billing enabled
- `gcloud` CLI, Docker, Git
- API keys: OpenAI, LlamaParse, Tavily

## Architecture
- Container: Docker (Python 3.13.2)
- Platform: Google Cloud Run (serverless)
- Storage: Google Cloud Storage
- Secrets: Google Secret Manager
- CI/CD: Google Cloud Build

## Local Testing

### Docker Run
```bash
# Build image
docker build -t reportcard-rag:local .

# Run container
docker run -p 8081:8080 \
  --env-file .env.docker \
  -v $(pwd)/data/indices:/app/data/indices \
  -v $(pwd)/data/uploads:/app/data/uploads \
  -v $(pwd)/logs:/app/logs \
  reportcard-rag:local

# Or use the test script
./test-docker.sh
```

## Google Cloud Deployment

### 1. Configure Environment
```bash
# Create project
gcloud projects create reportcard-rag-project --name="Report Card RAG Chatbot"
gcloud config set project reportcard-rag-project

# Enable APIs
gcloud services enable cloudbuild.googleapis.com run.googleapis.com \
  secretmanager.googleapis.com storage.googleapis.com artifactregistry.googleapis.com

# Create storage
gsutil mb -l us-central1 gs://reportcard-indices/
gsutil mb -l us-central1 gs://reportcard-uploads/

# Create artifact repository
gcloud artifacts repositories create reportcard-repo \
  --repository-format=docker --location=us-central1
```

### 2. Configure Secrets
```bash
# Store API keys
echo -n "your-openai-api-key" | gcloud secrets create openai-api-key --data-file=-
echo -n "your-llamaparse-api-key" | gcloud secrets create llamaparse-api-key --data-file=-
echo -n "your-tavily-api-key" | gcloud secrets create tavily-api-key --data-file=-

# Configure service account
SERVICE_ACCOUNT="reportcard-rag-chatbot@reportcard-rag-project.iam.gserviceaccount.com"
gcloud iam service-accounts create reportcard-rag-chatbot \
  --display-name="Report Card RAG Chatbot Service Account"

# Grant access to secrets
for SECRET in openai-api-key llamaparse-api-key tavily-api-key; do
  gcloud secrets add-iam-policy-binding $SECRET \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/secretmanager.secretAccessor"
done
```

### 3. Deploy Application
```bash
# Manual deployment
docker build -t us-central1-docker.pkg.dev/reportcard-rag-project/reportcard-repo/reportcard-rag-chatbot:latest .
docker push us-central1-docker.pkg.dev/reportcard-rag-project/reportcard-repo/reportcard-rag-chatbot:latest

gcloud run deploy reportcard-rag-chatbot \
  --image=us-central1-docker.pkg.dev/reportcard-rag-project/reportcard-repo/reportcard-rag-chatbot:latest \
  --region=us-central1 --platform=managed --allow-unauthenticated \
  --cpu=2 --memory=4Gi --min-instances=0 --max-instances=10 \
  --set-env-vars="EMBED_MODEL=text-embedding-3-large,LLM_MODEL=gpt-4o,TEMPERATURE=0.2" \
  --set-secrets="OPENAI_API_KEY=openai-api-key:latest,LLAMA_PARSE_API_KEY=llamaparse-api-key:latest,TAVILY_API_KEY=tavily-api-key:latest"

# Or CI/CD with Cloud Build
gcloud builds triggers create github \
  --repo-name=reportcard-rag-chatbot \
  --repo-owner=zacharyvunguyen \
  --branch-pattern=deployment \
  --build-config=cloudbuild.yaml
```

### 4. Monitor & Maintain
```bash
# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=reportcard-rag-chatbot"

# Rollback if needed
gcloud run revisions list --service=reportcard-rag-chatbot --region=us-central1
gcloud run services update-traffic reportcard-rag-chatbot --region=us-central1 --to-revisions=REVISION_ID=100
```

## Deployment Checklist
- [ ] GCP environment configured
- [ ] Secrets stored in Secret Manager
- [ ] Docker image built and tested locally ✓
- [ ] CI/CD pipeline configured
- [ ] Application deployed to Cloud Run
- [ ] Monitoring set up

## Deployment History
| Date | Version | Notes |
|------|---------|-------|
| 2025-04-08 | v1.0.0 | Initial Docker deployment | 