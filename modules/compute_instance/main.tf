resource "google_compute_instance" "this" {
  project      = var.project_id
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  tags         = var.tags
  labels       = var.labels

  boot_disk {
    initialize_params {
      # Image is passed as a self link so it can come from a different project.
      image = var.source_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id

    # No access_config means no external IP. Enable only when public access is needed.
    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {}
    }
  }

  # Null email uses the Compute Engine default service account.
  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  # Harden the VM boot chain when the source image supports Shielded VM.
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  lifecycle {
    # Let admins manage instance-level SSH keys without Terraform removing them.
    ignore_changes = [
      metadata["ssh-keys"]
    ]
  }
}
