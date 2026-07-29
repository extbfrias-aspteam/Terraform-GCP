output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "Endpoint del clúster de desarrollo."
}

output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "Nombre del clúster de desarrollo."
}

output "gcloud_connect_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}
