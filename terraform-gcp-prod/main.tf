# ==============================================================================
# MAIN GKE PRODUCTION DEPLOYMENT
# ==============================================================================

# 1. Cuenta de servicio dedicada para los nodos de GKE (Principio de privilegios mínimos)
resource "google_service_account" "gke_nodes" {
  project      = var.project_id
  account_id   = "sa-gke-banking-nodes"
  display_name = "GKE Nodes Production Service Account"
}

# 2. Roles mínimos de IAM requeridos para que los nodos funcionen y reporten métricas/logs
resource "google_project_iam_member" "node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader" # Permite descargar imágenes de Artifact Registry de producción
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# 3. Clúster de GKE (Plano de Control HA Regional)
resource "google_container_cluster" "primary" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.region

  # Alta Disponibilidad (HA) distribuyendo los recursos a través de 3 zonas
  node_locations = [
    "${var.region}-a",
    "${var.region}-c",
    "${var.region}-f"
  ]

  network    = var.vpc_network
  subnetwork = var.subnet

  # Práctica Recomendada: Eliminar el pool por defecto (que se crea con credenciales básicas)
  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"

  # Asignación de rangos secundarios de red (VPC-Native)
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Configuración del Clúster Privado (Nodos aislados de internet)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Permite acceso público seguro al endpoint del Master mediante Redes Autorizadas
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Habilitación de Workload Identity para vincular Kube ServiceAccounts con IAM de GCP
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Seguridad del plano de control y del sistema operativo de los nodos
  enable_shielded_nodes = true

  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_DISABLED"
  }

  release_channel {
    channel = "REGULAR"
  }

  # Control Plane Authorized Networks (Solo IPs de la VPN de la empresa o bastiones pueden comunicarse con la API de K8s)
  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false
    
    # Ejemplo de red corporativa autorizada (se recomienda configurar según sus CIDRs reales)
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal Corporative Network"
    }
  }
}

# 4. Node Pool de Producción Dedicado para Aplicaciones de Banca
resource "google_container_node_pool" "banking_pool" {
  project    = var.project_id
  name       = "banking-pool-prod"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  
  initial_node_count = 1

  # Escalabilidad dinámica basada en demanda de carga
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    image_type   = "COS_CONTAINERD" # Container-Optimized OS de Google
    
    service_account = google_service_account.gke_nodes.email
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Medidas avanzadas de seguridad en el hipervisor/instancia
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Requerido explícitamente para asegurar el correcto funcionamiento de Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      environment = "production"
      app         = "banking"
    }

    tags = ["gke-banking-node", "prod"]
  }
}
