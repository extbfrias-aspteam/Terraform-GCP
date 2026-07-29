# ==============================================================================
# PROVIDERS & BACKEND CONFIGURATION
# ==============================================================================

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
  
  # Backend remoto en GCS para asegurar consistencia del estado en producción
  backend "gcs" {
    bucket = "prj-hypertech-prod-tfstate"
    prefix = "gke/production-cluster"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
