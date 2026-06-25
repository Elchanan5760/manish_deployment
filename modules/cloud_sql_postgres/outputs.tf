output "instance_name" {
  description = "Cloud SQL instance name."
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "Cloud SQL connection name."
  value       = google_sql_database_instance.this.connection_name
}

output "database_names" {
  description = "Database names by key."
  value       = { for key, database in google_sql_database.this : key => database.name }
}

output "user_names" {
  description = "SQL user names by key."
  value       = { for key, user in google_sql_user.this : key => user.name }
}

output "private_ip_address" {
  description = "Private IP address."
  value       = google_sql_database_instance.this.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address if enabled."
  value       = google_sql_database_instance.this.public_ip_address
}

output "connection_host" {
  description = "Host used by the PostgreSQL provider."
  value       = var.enable_public_ip ? google_sql_database_instance.this.public_ip_address : google_sql_database_instance.this.private_ip_address
}
