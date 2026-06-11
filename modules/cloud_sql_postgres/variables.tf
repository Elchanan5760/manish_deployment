variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Cloud SQL region."
  type        = string
}

variable "instance_name" {
  description = "Cloud SQL instance name."
  type        = string
}

variable "database_name" {
  description = "Initial database name."
  type        = string
}

variable "admin_user_name" {
  description = "Admin application user name."
  type        = string
}

variable "admin_user_password" {
  description = "Admin application user password."
  type        = string
  sensitive   = true
}

variable "database_version" {
  description = "Cloud SQL PostgreSQL version."
  type        = string
  default     = "POSTGRES_17"
}

variable "tier" {
  description = "Cloud SQL machine tier."
  type        = string
}

variable "disk_size_gb" {
  description = "Cloud SQL SSD disk size in GB."
  type        = number
}

variable "availability_type" {
  description = "Cloud SQL availability type."
  type        = string
}

variable "deletion_protection" {
  description = "Protect instance from accidental deletion."
  type        = bool
}

variable "private_network_id" {
  description = "VPC network self link or ID for private IP."
  type        = string
}

variable "enable_public_ip" {
  description = "Whether the instance should have a public IPv4 address."
  type        = bool
}

variable "authorized_networks" {
  description = "Authorized public networks when public IP is enabled."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "backup_start_time" {
  description = "UTC time for daily backups."
  type        = string
  default     = "01:00"
}
