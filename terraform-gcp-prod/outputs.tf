# ==============================================================================
# OUTPUTS
# ==============================================================================

output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "El Endpoint privado/público del plano de control de GKE."
}

output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "El nombre del clúster de GKE."
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
  description = "El certificado CA público del clúster de producción."
}

output "gcloud_connect_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
  description = "Comando gcloud listo para ejecutar y conectar la terminal local con el clúster."
}
