# ==============================================================================
# INPUT VARIABLES - DEV
# ==============================================================================

variable "project_id" {
  type        = string
  description = "El ID del proyecto de GCP para el entorno de desarrollo."
  default     = "prj-hypertech-dev"
}

variable "region" {
  type        = string
  description = "Región de GCP para el entorno."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Zona específica donde correrá el clúster de un solo nodo (Zonal)."
  default     = "us-central1-a"
}

variable "vpc_network" {
  type        = string
  description = "VPC asignada al entorno de desarrollo."
  default     = "vpc-dev-shared"
}

variable "subnet" {
  type        = string
  description = "Subred asignada al entorno de desarrollo."
  default     = "subnet-dev-1"
}

variable "cluster_name" {
  type        = string
  default     = "banking-cluster-dev"
}

variable "machine_type" {
  type        = string
  description = "Tipo de máquina económico para desarrollo."
  default     = "e2-medium" # 2 vCPUs, 4GB RAM
}

variable "pod_secondary_range_name" {
  type    = string
  default = "pods-dev"
}

variable "services_secondary_range_name" {
  type    = string
  default = "services-dev"
}

variable "master_ipv4_cidr_block" {
  type    = string
  default = "172.16.1.0/28"
}
