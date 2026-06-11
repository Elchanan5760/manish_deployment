variable "project_id" {
  description = "The new GCP project ID where resources will be created."
  type        = string
}

variable "region" {
  description = "Default GCP region for regional resources."
  type        = string
  default     = "me-west1"
}

variable "network_project_id" {
  description = "Shared VPC host project ID that owns the VPC network. Defaults to project_id for same-project networking."
  type        = string
  default     = null
}

variable "network_name" {
  description = "Shared VPC network name used by Cloud SQL private IP and the VM."
  type        = string
  default     = "default"
}

variable "subnetwork_name" {
  description = "Shared VPC subnetwork name for the VM. Set this when using Shared VPC."
  type        = string
  default     = null
}

variable "subnetwork_region" {
  description = "Region of the Shared VPC subnetwork for the VM."
  type        = string
  default     = "me-west1"
}

variable "db_instance_name" {
  description = "Cloud SQL PostgreSQL instance name."
  type        = string
  default     = "manish-postgres"
}

variable "db_name" {
  description = "Initial PostgreSQL database name where PostGIS will be enabled."
  type        = string
  default     = "app"
}

variable "db_admin_user" {
  description = "Cloud SQL PostgreSQL user used by Terraform to enable extensions. Use postgres or another role allowed to create extensions."
  type        = string
  default     = "postgres"
}

variable "db_admin_password" {
  description = "Password for db_admin_user. Leave null to generate one automatically."
  type        = string
  default     = null
  sensitive   = true
}

variable "db_tier" {
  description = "Cloud SQL machine tier."
  type        = string
  default     = "db-custom-4-16384"
}

variable "db_disk_size_gb" {
  description = "Cloud SQL SSD disk size in GB. 1331 GB is approximately 1.3 TiB."
  type        = number
  default     = 1331
}

variable "db_availability_type" {
  description = "Cloud SQL availability type. Use REGIONAL for HA production workloads."
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.db_availability_type)
    error_message = "db_availability_type must be ZONAL or REGIONAL."
  }
}

variable "db_deletion_protection" {
  description = "Protect the Cloud SQL instance from accidental deletion."
  type        = bool
  default     = true
}

variable "enable_public_ip" {
  description = "Whether Cloud SQL should have a public IPv4 address. Keep false unless Terraform cannot reach private IP."
  type        = bool
  default     = false
}

variable "authorized_networks" {
  description = "Public authorized networks for Cloud SQL, only used when enable_public_ip is true."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "postgresql_sslmode" {
  description = "SSL mode used by the PostgreSQL Terraform provider."
  type        = string
  default     = "require"
}

variable "enable_project_services" {
  description = "Whether Terraform should enable required project APIs."
  type        = bool
  default     = true
}

variable "vm_name" {
  description = "Compute Engine VM instance name."
  type        = string
  default     = "manish-vm"
}

variable "vm_zone" {
  description = "Compute Engine zone for the VM."
  type        = string
  default     = "me-west1-a"
}

variable "vm_machine_type" {
  description = "Compute Engine machine type for the VM."
  type        = string
  default     = "e2-standard-4"
}

variable "vm_boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 100
}

variable "vm_boot_disk_type" {
  description = "Boot disk type."
  type        = string
  default     = "pd-balanced"
}

variable "vm_image_project_id" {
  description = "Project ID that owns the source VM image, even when it belongs to another organization. The Terraform identity must be allowed to use it."
  type        = string
}

variable "vm_image_name" {
  description = "Exact source image name. Leave null when using vm_image_family."
  type        = string
  default     = null
}

variable "vm_image_family" {
  description = "Source image family. Leave null when using vm_image_name."
  type        = string
  default     = null
}

variable "vm_assign_public_ip" {
  description = "Whether to assign an ephemeral public IP to the VM. Default is private-only."
  type        = bool
  default     = false
}

variable "vm_tags" {
  description = "Network tags for the VM."
  type        = list(string)
  default     = []
}

variable "vm_labels" {
  description = "Labels for the VM."
  type        = map(string)
  default     = {}
}

variable "vm_service_account_email" {
  description = "Service account email for the VM. Leave null to use the Compute Engine default service account."
  type        = string
  default     = null
}

variable "vm_service_account_scopes" {
  description = "OAuth scopes for the VM service account."
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "existing_group_email" {
  description = "Existing Google Group email to grant IAM access to. Example: platform-team@example.com."
  type        = string
  default     = null
}

variable "existing_group_project_roles" {
  description = "Project-level IAM roles to grant to existing_group_email."
  type        = set(string)
  default     = []
}

variable "existing_group_bucket_roles" {
  description = "Bucket-level IAM roles to grant to existing_group_email on all buckets created by this Terraform."
  type        = set(string)
  default     = []
}
