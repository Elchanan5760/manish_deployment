variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "name" {
  description = "VM instance name."
  type        = string
}

variable "zone" {
  description = "VM zone."
  type        = string
}

variable "machine_type" {
  description = "VM machine type."
  type        = string
}

variable "network_id" {
  description = "VPC network self link or ID."
  type        = string
}

variable "subnetwork_id" {
  description = "Subnetwork self link. Use this for Shared VPC subnet attachment."
  type        = string
  default     = null
}

variable "source_image" {
  description = "Source image self link."
  type        = string
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
}

variable "boot_disk_type" {
  description = "Boot disk type."
  type        = string
}

variable "boot_disk_auto_delete" {
  description = "Whether to delete the boot disk when deleting the VM."
  type        = bool
  default     = true
}

variable "assign_public_ip" {
  description = "Whether to attach an ephemeral public IP."
  type        = bool
}

variable "tags" {
  description = "Network tags."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels."
  type        = map(string)
  default     = {}
}

variable "metadata" {
  description = "Instance metadata."
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled for the VM."
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Service account email. Null uses the Compute Engine default service account."
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "OAuth scopes for the VM service account."
  type        = list(string)
}

variable "automatic_restart" {
  description = "Whether the VM automatically restarts after host errors."
  type        = bool
  default     = true
}

variable "on_host_maintenance" {
  description = "Maintenance behavior for standard VMs."
  type        = string
  default     = "MIGRATE"
}

variable "preemptible" {
  description = "Whether the VM is preemptible."
  type        = bool
  default     = false
}

variable "provisioning_model" {
  description = "VM provisioning model."
  type        = string
  default     = "STANDARD"
}
