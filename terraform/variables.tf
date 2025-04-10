variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "reportcard-rag"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "enable_cloud_run" {
  description = "Whether to deploy the Cloud Run service"
  type        = bool
  default     = false
}

variable "service_name" {
  description = "Name for the Cloud Run service"
  type        = string
  default     = "reportcard-rag-app"
}

variable "container_image" {
  description = "Container image for Cloud Run service"
  type        = string
  default     = "gcr.io/reportcard-rag/reportcard-chatbot:latest"
}

variable "embedding_dimensions" {
  description = "Dimensions for the embedding vectors"
  type        = number
  default     = 1536
}

variable "min_replicas" {
  description = "Minimum number of replicas for Cloud Run"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of replicas for Cloud Run"
  type        = number
  default     = 10
} 