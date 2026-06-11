variable "name" {
  description = "Cloud Storage bucket name."
  type        = string
}

variable "location" {
  description = "Cloud Storage bucket location."
  type        = string
}

variable "storage_class" {
  description = "Default storage class."
  type        = string
  default     = "STANDARD"
}

variable "public_access_prevention" {
  description = "Public access prevention setting."
  type        = string
  default     = "inherited"

  validation {
    condition     = contains(["enforced", "inherited"], var.public_access_prevention)
    error_message = "public_access_prevention must be enforced or inherited."
  }
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention in days."
  type        = number
  default     = 7
}

variable "force_destroy" {
  description = "Whether Terraform can delete the bucket when objects exist."
  type        = bool
  default     = false
}
