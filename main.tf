locals {
  # For Shared VPC, set network_project_id to the host project.
  # For standalone projects, leave it null and the service project is used.
  network_project_id = coalesce(var.network_project_id, var.project_id)
  vm_image_is_set    = var.vm_image_name != null || var.vm_image_family != null

  # Google IAM expects group principals in this exact format.
  existing_group_member = var.existing_group_email == null ? null : "group:${var.existing_group_email}"

  # Uses provided database passwords when set, otherwise generated passwords.
  db_passwords = {
    for key, database in var.db_databases :
    key => database.password != null ? database.password : random_password.db_database[key].result
  }

  db_secret_ids = {
    for key, database in var.db_databases :
    key => coalesce(database.secret_id, "${var.db_instance_name}-${database.database_name}-${database.user_name}-password")
  }

  # Bucket settings mirror the three existing buckets provided in the request.
  buckets = {
    manishtana_csv_stage = {
      name                       = "manishtana_csv_stage_hrz"
      location                   = "me-west1"
      storage_class              = "STANDARD"
      public_access_prevention   = "inherited"
      soft_delete_retention_days = 7
      force_destroy              = false
    }

    migrate_sql_ayen_geo_map_int_manish_1 = {
      name                       = "migrate-sql-ayen-geo-map-int-manish-1_hrz"
      location                   = "me-west1"
      storage_class              = "STANDARD"
      public_access_prevention   = "inherited"
      soft_delete_retention_days = 7
      force_destroy              = false
    }

    research_manish = {
      name                       = "research_manish_hrz"
      location                   = "me-west1"
      storage_class              = "STANDARD"
      public_access_prevention   = "inherited"
      soft_delete_retention_days = 7
      force_destroy              = false
    }
  }

  # Expands the selected bucket IAM roles across every bucket in local.buckets.
  existing_group_bucket_iam = {
    for binding in flatten([
      for bucket_key, bucket in local.buckets : [
        for role in var.existing_group_bucket_roles : {
          key    = "${bucket_key}-${role}"
          bucket = bucket.name
          role   = role
        }
      ]
    ]) : binding.key => binding
  }
}

resource "random_password" "db_database" {
  for_each = {
    for key, database in var.db_databases :
    key => database
    if database.password == null
  }

  length  = 24
  special = false
}

resource "google_secret_manager_secret" "db_password" {
  for_each = var.db_databases

  project   = var.project_id
  secret_id = local.db_secret_ids[each.key]

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  for_each = var.db_databases

  secret      = google_secret_manager_secret.db_password[each.key].id
  secret_data = local.db_passwords[each.key]
}

# Optional project-level access for an existing Google Group.
# Leave existing_group_email or existing_group_project_roles empty to skip this.
resource "google_project_iam_member" "existing_group" {
  for_each = local.existing_group_member == null ? toset([]) : var.existing_group_project_roles

  project = var.project_id
  role    = each.value
  member  = local.existing_group_member
}

# Optional bucket-level access for the same existing Google Group on all buckets.
resource "google_storage_bucket_iam_member" "existing_group" {
  for_each = local.existing_group_member == null ? {} : local.existing_group_bucket_iam

  bucket = each.value.bucket
  role   = each.value.role
  member = local.existing_group_member

  depends_on = [module.buckets]
}

# Cloud SQL private IP requires a reserved peering range for Service Networking.
# Network ID is provided directly as a variable to avoid requiring compute.networks.get
# permission on the Shared VPC host project.
# resource "google_compute_global_address" "private_service_access" {
#   project       = local.network_project_id
#   name          = "${var.db_instance_name}-private-service-access"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = var.private_network_id
# }

# Creates the private services access connection used by Cloud SQL.
# resource "google_service_networking_connection" "private_service_access" {
#   network                 = var.private_network_id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
# }

# Creates the three regional GCS buckets using the shared bucket module.
module "buckets" {
  source = "./modules/gcs_bucket"

  for_each = local.buckets

  name                       = each.value.name
  location                   = each.value.location
  storage_class              = each.value.storage_class
  public_access_prevention   = each.value.public_access_prevention
  soft_delete_retention_days = each.value.soft_delete_retention_days
  force_destroy              = each.value.force_destroy
}

# VM boot disk is initialized from the cross-project image resolved above.
# Uncomment when ready to deploy the VM. Requires:
#   - var.subnetwork_id: full self_link of the Shared VPC subnet
#   - var.vm_image_name or var.vm_image_family: source image in var.vm_image_project_id
#   - roles/compute.imageUser on the image project for the Terraform SA
module "vm" {
  source = "./modules/compute_instance"

  project_id             = var.project_id
  name                   = var.vm_name
  zone                   = var.vm_zone
  machine_type           = var.vm_machine_type
  network_id             = var.private_network_id
  subnetwork_id          = var.subnetwork_id
  source_image           = var.vm_image_name
  boot_disk_size_gb      = var.vm_boot_disk_size_gb
  boot_disk_type         = var.vm_boot_disk_type
  boot_disk_auto_delete  = var.vm_boot_disk_auto_delete
  assign_public_ip       = var.vm_assign_public_ip
  tags                   = var.vm_tags
  labels                 = var.vm_labels
  metadata               = var.vm_metadata
  deletion_protection    = var.vm_deletion_protection
  service_account_email  = var.vm_service_account_email
  service_account_scopes = var.vm_service_account_scopes
  automatic_restart      = var.vm_automatic_restart
  on_host_maintenance    = var.vm_on_host_maintenance
  preemptible            = var.vm_preemptible
  provisioning_model     = var.vm_provisioning_model
}

# PostgreSQL Cloud SQL instance, database, and SQL user.
module "postgres" {
  source = "./modules/cloud_sql_postgres"

  project_id    = var.project_id
  region        = var.region
  instance_name = var.db_instance_name
  databases = {
    for key, database in var.db_databases :
    key => {
      database_name = database.database_name
      user_name     = database.user_name
      password      = local.db_passwords[key]
    }
  }
  tier                = var.db_tier
  disk_size_gb        = var.db_disk_size_gb
  availability_type   = var.db_availability_type
  deletion_protection = var.db_deletion_protection
  private_network_id  = var.private_network_id
  enable_public_ip    = var.enable_public_ip
  authorized_networks = var.authorized_networks

  # depends_on = [google_service_networking_connection.private_service_access]
}

# PostGIS is a database extension, so it is managed with the PostgreSQL provider.
# resource "postgresql_extension" "postgis" {
#   name     = "postgis"
#   database = module.postgres.database_name

#   depends_on = [module.postgres]
# }
