output "name" {
  description = "Cloud Storage bucket name."
  value       = google_storage_bucket.this.name
}

output "url" {
  description = "Cloud Storage bucket URL."
  value       = google_storage_bucket.this.url
}

