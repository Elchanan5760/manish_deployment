output "name" {
  description = "VM instance name."
  value       = google_compute_instance.this.name
}

output "self_link" {
  description = "VM instance self link."
  value       = google_compute_instance.this.self_link
}

output "internal_ip" {
  description = "VM internal IP address."
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "external_ip" {
  description = "VM external IP address, if enabled."
  value       = try(google_compute_instance.this.network_interface[0].access_config[0].nat_ip, null)
}

