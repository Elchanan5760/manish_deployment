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

variable "private_network_id" {
  type        = string
  description = "Full network ID of the Shared VPC. E.g. projects/hrz-manish-net-0/global/networks/manish-0"
}

variable "subnetwork_id" {
  type        = string
  description = "Full subnetwork self_link. E.g. projects/hrz-manish-net-0/regions/me-west1/subnetworks/manish-subnet-0"
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

variable "db_databases" {
  description = "Databases and users to create. Each password is generated unless explicitly provided, and is stored in Secret Manager."
  type = map(object({
    database_name = string
    user_name     = string
    password      = optional(string)
    secret_id     = optional(string)
  }))
  default = {
    main = {
      database_name = "app"
      user_name     = "app"
    }
    secondary = {
      database_name = "app_secondary"
      user_name     = "app_secondary"
    }
  }
}

variable "db_provider_database_key" {
  description = "Key from db_databases used by the PostgreSQL provider."
  type        = string
  default     = "main"

  validation {
    condition     = contains(keys(var.db_databases), var.db_provider_database_key)
    error_message = "db_provider_database_key must be one of the keys in db_databases."
  }
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
  description = "Compute Engine VM instance name. Set per project/environment; this is intentionally not derived from the source VM."
  type        = string
}

variable "vm_zone" {
  description = "Compute Engine zone for the VM."
  type        = string
  default     = "me-west1-c"
}

variable "vm_machine_type" {
  description = "Compute Engine machine type for the VM."
  type        = string
  default     = "e2-standard-8"
}

variable "vm_boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 500
}

variable "vm_boot_disk_type" {
  description = "Boot disk type."
  type        = string
  default     = "pd-balanced"
}

variable "vm_boot_disk_auto_delete" {
  description = "Whether to delete the boot disk when deleting the VM."
  type        = bool
  default     = true
}

variable "vm_image_name" {
  description = "Exact source image self link or project image path."
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20250508"
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
  default     = ["allow-internet"]
}

variable "vm_labels" {
  description = "Labels for the VM."
  type        = map(string)
  default     = {}
}

variable "vm_metadata" {
  description = "Metadata for OS Login and OS Config."
  type        = map(string)
  default = {
    enable-osconfig = "TRUE"
    enable-oslogin  = "true"
  }
}

variable "vm_deletion_protection" {
  description = "Whether deletion protection is enabled for the VM."
  type        = bool
  default     = false
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

variable "vm_automatic_restart" {
  description = "Whether the VM automatically restarts after host errors."
  type        = bool
  default     = true
}

variable "vm_on_host_maintenance" {
  description = "Maintenance behavior for standard VMs."
  type        = string
  default     = "MIGRATE"
}

variable "vm_preemptible" {
  description = "Whether the VM is preemptible."
  type        = bool
  default     = false
}

variable "vm_provisioning_model" {
  description = "VM provisioning model."
  type        = string
  default     = "STANDARD"
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
