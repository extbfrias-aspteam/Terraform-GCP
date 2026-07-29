# ==============================================================================
# INPUT VARIABLES
# ==============================================================================

variable "project_id" {
  type        = string
  description = "El ID del proyecto de GCP para el entorno de producción."
  default     = "prj-hypertech-prod"
}

variable "region" {
  type        = string
  description = "Región de GCP donde se desplegarán el clúster de GKE y la infraestructura."
  default     = "us-central1"
}

variable "vpc_network" {
  type        = string
  description = "El nombre o self_link de la VPC existente en producción."
  default     = "vpc-prod-shared"
}

variable "subnet" {
  type        = string
  description = "El nombre o self_link de la subred existente en producción."
  default     = "subnet-prod-2"
}

variable "cluster_name" {
  type        = string
  description = "Nombre del clúster de GKE en Producción."
  default     = "banking-cluster-prod"
}

variable "machine_type" {
  type        = string
  description = "Tipo de máquina GCE para las instancias del Node Pool."
  default     = "e2-standard-4"
}

variable "pod_secondary_range_name" {
  type        = string
  description = "El nombre del rango de IPs secundario en la subred asignado a los Pods."
  default     = "pods"
}

variable "services_secondary_range_name" {
  type        = string
  description = "El nombre del rango de IPs secundario en la subred asignado a los Servicios."
  default     = "services"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "Rango CIDR /28 reservado exclusivamente para la IP del plano de control (Control Plane) de GKE."
  default     = "172.16.0.0/28"
}
