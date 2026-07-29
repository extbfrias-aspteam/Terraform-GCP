# ==============================================================================
# PROVIDERS & BACKEND CONFIGURATION - DEV
# ==============================================================================

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
  
  # Backend remoto en el bucket de desarrollo
  backend "gcs" {
    bucket = "prj-hypertech-dev-tfstate"
    prefix = "gke/development-cluster"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
