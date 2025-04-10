terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = "reportcard-rag-tf-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enable required services
resource "google_project_service" "services" {
  for_each = toset([
    "aiplatform.googleapis.com",
    "firestore.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com"
  ])
  project = var.project_id
  service = each.key

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Create service account
resource "google_service_account" "app_service_account" {
  account_id   = "reportcard-rag-chatbot"
  display_name = "Report Card RAG Chatbot Service Account"
  depends_on   = [google_project_service.services["iam.googleapis.com"]]
}

# Create storage buckets
resource "google_storage_bucket" "indices_bucket" {
  name                        = "reportcard-rag-indices"
  location                    = var.region
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.services["storage.googleapis.com"]]
}

resource "google_storage_bucket" "uploads_bucket" {
  name                        = "reportcard-rag-uploads"
  location                    = var.region
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.services["storage.googleapis.com"]]
}

# Create Secret Manager secrets (without values)
resource "google_secret_manager_secret" "llama_parse_key" {
  secret_id = "llamaparse-api-key"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.services["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret" "openai_key" {
  secret_id = "openai-api-key"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.services["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret" "tavily_key" {
  secret_id = "tavily-api-key"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.services["secretmanager.googleapis.com"]]
}

# Grant service account access to secrets
resource "google_secret_manager_secret_iam_member" "app_secret_access" {
  for_each  = toset(["llamaparse-api-key", "openai-api-key", "tavily-api-key"])
  secret_id = each.key
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app_service_account.email}"
  depends_on = [
    google_secret_manager_secret.llama_parse_key,
    google_secret_manager_secret.openai_key,
    google_secret_manager_secret.tavily_key
  ]
}

# Create Firestore database
resource "google_firestore_database" "database" {
  name                   = "(default)"
  location_id            = var.region
  type                   = "FIRESTORE_NATIVE"
  concurrency_mode       = "PESSIMISTIC"
  app_engine_integration_mode = "DISABLED"
  depends_on             = [google_project_service.services["firestore.googleapis.com"]]
}

# Vertex AI Vector Search Index
resource "google_vertex_ai_index" "embeddings_index" {
  provider     = google-beta
  region       = var.region
  display_name = "reportcard-embeddings"
  description  = "Vector index for Report Card RAG application"
  
  metadata {
    contents_delta_uri = ""
    config {
      dimensions = 1536
      approximate_neighbors_count = 150
      distance_measure_type = "DOT_PRODUCT_DISTANCE"
      algorithm_config {
        tree_ah_config {
          leaf_node_embedding_count = 10000
          leaf_nodes_to_search_percent = 3
        }
      }
      shard_size = "SHARD_SIZE_MEDIUM"
    }
  }
  
  index_update_method = "BATCH_UPDATE"
  depends_on = [google_project_service.services["aiplatform.googleapis.com"]]
  
  # Index creation can take up to several minutes
  timeouts {
    create = "30m"
    update = "30m"
    delete = "20m"
  }
}

# Vertex AI Index Endpoint
resource "google_vertex_ai_index_endpoint" "endpoint" {
  provider     = google-beta
  region       = var.region
  display_name = "reportcard-endpoint"
  description  = "Endpoint for Report Card RAG vector search"
  depends_on   = [google_project_service.services["aiplatform.googleapis.com"]]
  
  # Endpoint creation can take a few minutes
  timeouts {
    create = "15m"
    update = "15m"
    delete = "10m"
  }
}

# Deploy Index to Endpoint
# Note: This deployment can take up to 30 minutes
resource "google_vertex_ai_index_endpoint_deployed_index" "deployed_index" {
  provider     = google-beta
  region       = var.region
  index_endpoint = google_vertex_ai_index_endpoint.endpoint.id
  deployed_index_id = "reportcard_deployed_index"
  display_name = "reportcard-deployed-index"
  index = google_vertex_ai_index.embeddings_index.id
  
  dedicated_resources {
    machine_spec {
      machine_type = "n1-standard-16"
    }
    min_replica_count = 1
    max_replica_count = 2
  }
  
  # Deployment can take up to 30 minutes
  timeouts {
    create = "45m"
    update = "45m"
    delete = "20m"
  }
}

# Grant service account access to buckets
resource "google_storage_bucket_iam_member" "uploads_bucket_access" {
  bucket = google_storage_bucket.uploads_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.app_service_account.email}"
}

resource "google_storage_bucket_iam_member" "indices_bucket_access" {
  bucket = google_storage_bucket.indices_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.app_service_account.email}"
}

# Grant service account access to Firestore
resource "google_project_iam_member" "firestore_access" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# Grant service account access to Vertex AI
resource "google_project_iam_member" "vertex_ai_access" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# Cloud Run service (conditional deployment)
resource "google_cloud_run_service" "app" {
  count    = var.enable_cloud_run ? 1 : 0
  name     = var.service_name
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.app_service_account.email
      containers {
        image = var.container_image
        
        env {
          name  = "GCP_PROJECT"
          value = var.project_id
        }
        
        env {
          name  = "GCP_REGION"
          value = var.region
        }
        
        env {
          name  = "GCS_BUCKET_INDICES"
          value = google_storage_bucket.indices_bucket.name
        }
        
        env {
          name  = "GCS_BUCKET_UPLOADS"
          value = google_storage_bucket.uploads_bucket.name
        }
        
        env {
          name  = "EMBED_MODEL"
          value = "textembedding-gecko@003"
        }
        
        # Secret refs
        env {
          name = "OPENAI_API_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.openai_key.secret_id
              key  = "latest"
            }
          }
        }
        
        env {
          name = "LLAMA_PARSE_API_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.llama_parse_key.secret_id
              key  = "latest"
            }
          }
        }
        
        env {
          name = "TAVILY_API_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.tavily_key.secret_id
              key  = "latest"
            }
          }
        }
        
        resources {
          limits = {
            cpu    = "2"
            memory = "4Gi"
          }
        }
      }
      
      timeout_seconds = 300
      container_concurrency = 10
    }
    
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = var.min_replicas
        "autoscaling.knative.dev/maxScale" = var.max_replicas
        "run.googleapis.com/client-name"   = "terraform"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.services["run.googleapis.com"],
    google_secret_manager_secret.openai_key,
    google_secret_manager_secret.llama_parse_key,
    google_secret_manager_secret.tavily_key
  ]
}

# Make the Cloud Run service publicly accessible
resource "google_cloud_run_service_iam_member" "public_access" {
  count    = var.enable_cloud_run ? 1 : 0
  service  = google_cloud_run_service.app[0].name
  location = google_cloud_run_service.app[0].location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Output variables
output "indices_bucket" {
  description = "GCS bucket for indices storage"
  value       = google_storage_bucket.indices_bucket.name
}

output "uploads_bucket" {
  description = "GCS bucket for report card uploads"
  value       = google_storage_bucket.uploads_bucket.name
}

output "service_account" {
  description = "Service account email"
  value       = google_service_account.app_service_account.email
}

output "cloud_run_url" {
  description = "URL of the deployed Cloud Run service"
  value       = var.enable_cloud_run ? google_cloud_run_service.app[0].status[0].url : "Cloud Run not enabled"
} 