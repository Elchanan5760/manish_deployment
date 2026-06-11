output "bucket_names" {
  description = "Created Cloud Storage bucket names."
  value       = { for key, bucket in module.buckets : key => bucket.name }
}

output "cloud_sql_instance_name" {
  description = "Cloud SQL PostgreSQL instance name."
  value       = module.postgres.instance_name
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name in project:region:instance format."
  value       = module.postgres.connection_name
}

output "cloud_sql_private_ip_address" {
  description = "Cloud SQL private IP address."
  value       = module.postgres.private_ip_address
}

output "db_admin_password" {
  description = "Generated or provided Cloud SQL admin password."
  value       = local.db_admin_password
  sensitive   = true
}

output "vm_name" {
  description = "Compute Engine VM instance name."
  value       = module.vm.name
}

output "vm_self_link" {
  description = "Compute Engine VM self link."
  value       = module.vm.self_link
}

output "vm_internal_ip" {
  description = "Compute Engine VM internal IP address."
  value       = module.vm.internal_ip
}

output "vm_external_ip" {
  description = "Compute Engine VM external IP address, if enabled."
  value       = module.vm.external_ip
}
