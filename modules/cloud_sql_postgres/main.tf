resource "google_sql_database_instance" "this" {
  project             = var.project_id
  name                = var.instance_name
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size_gb
    disk_autoresize   = true

    backup_configuration {
      # PITR keeps transaction logs so the database can recover to a recent time.
      enabled                        = true
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }

    ip_configuration {
      # Private IP is the default path; public IP is controlled by enable_public_ip.
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network_id

      # Authorized networks are ignored unless public IP is enabled.
      dynamic "authorized_networks" {
        for_each = var.enable_public_ip ? var.authorized_networks : []

        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    # Query Insights helps troubleshoot expensive queries after migration.
    insights_config {
      query_insights_enabled  = true
      record_application_tags = true
      record_client_address   = true
    }

    # Stable maintenance window keeps disruptive updates predictable.
    maintenance_window {
      day          = 7
      hour         = 2
      update_track = "stable"
    }
  }
}

resource "google_sql_database" "this" {
  for_each = var.databases

  project  = var.project_id
  name     = each.value.database_name
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "this" {
  for_each = var.databases

  project  = var.project_id
  name     = each.value.user_name
  instance = google_sql_database_instance.this.name
  password = each.value.password
}
