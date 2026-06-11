resource "google_storage_bucket" "this" {
  name                        = var.name
  location                    = var.location
  storage_class               = var.storage_class
  # Required for uniform IAM management; object ACLs are not used.
  uniform_bucket_level_access = true
  public_access_prevention    = var.public_access_prevention
  force_destroy               = var.force_destroy

  # Matches the 7-day soft delete policy from the existing bucket settings.
  soft_delete_policy {
    retention_duration_seconds = var.soft_delete_retention_days * 24 * 60 * 60
  }
}
