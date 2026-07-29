# ==============================================================================
# MAIN GKE DEVELOPMENT DEPLOYMENT (HIGHLY COST-OPTIMIZED)
# ==============================================================================

# Cuenta de servicio de nodos de desarrollo
resource "google_service_account" "gke_nodes_dev" {
  project      = var.project_id
  account_id   = "sa-gke-banking-nodes-dev"
  display_name = "GKE Nodes Development Service Account"
}

# Permisos mínimos requeridos en el proyecto de DEV
resource "google_project_iam_member" "node_roles_dev" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes_dev.email}"
}

# Clúster de GKE Zonal (Usa la zona del Master para hospedar todos los nodos)
resource "google_container_cluster" "primary" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.zone # GKE Zonal elimina cargos extras de control plane redundante regional

  network    = var.vpc_network
  subnetwork = var.subnet

  remove_default_node_pool = true
  initial_node_count       = 1
  networking_mode          = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Configuración de Autoscaling optimizada y ajustada
  cluster_autoscaling {
    enabled             = true
    autoscaling_profile = "OPTIMIZE_UTILIZATION" # Empaqueta Pods de forma densa
    
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 8 # Límite estricto de presupuesto en DEV
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 4
      maximum       = 32
    }
  }

  addons_config {
    gke_backup_agent_config {
      enabled = false # DESACTIVADO: Ahorra el costo del agente de backup en DEV
    }
  }

  cost_management_config {
    enabled = true # Permite monitorear costos en desarrollo por Namespace
  }

  enable_shielded_nodes = true

  release_channel {
    channel = "REGULAR"
  }
}

# Pool de Nodos 100% SPOT para Desarrollo
resource "google_container_node_pool" "dev_nodes" {
  project    = var.project_id
  name       = "banking-pool-dev-spot"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  
  initial_node_count = 1

  # Autoscaling acotado para desarrollo
  autoscaling {
    min_node_count = 1 # Mantiene el clúster activo
    max_node_count = 3 # Máximo 3 nodos pequeños para no inflar la factura
  }

  node_config {
    machine_type    = var.machine_type # e2-medium (económico)
    image_type      = "COS_CONTAINERD"
    service_account = google_service_account.gke_nodes_dev.email
    
    # Práctica Recomendada: Cómputo 100% Spot para desarrollo
    spot = true

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      "cloud.google.com/gke-spot" = "true"
      "environment"               = "development"
    }
  }
}
