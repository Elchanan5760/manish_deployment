locals {
  # For Shared VPC, set network_project_id to the host project.
  # For standalone projects, leave it null and the service project is used.
  network_project_id = coalesce(var.network_project_id, var.project_id)
  vm_image_is_set    = var.vm_image_name != null || var.vm_image_family != null

  # Google IAM expects group principals in this exact format.
  existing_group_member = var.existing_group_email == null ? null : "group:${var.existing_group_email}"

  # Uses a provided password when set, otherwise the generated random password.
  db_admin_password = coalesce(var.db_admin_password, random_password.db_admin.result)

  # Keep API enablement close to the resources that require these services.
  required_project_services = toset([
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com"
  ])

  # Shared VPC host project needs these APIs for network lookup, peering, and subnets.
  required_network_project_services = toset([
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ])

  # Bucket settings mirror the three existing buckets provided in the request.
  buckets = {
    manishtana_csv_stage = {
      name                       = "manishtana_csv_stage"
      location                   = "me-west1"
      storage_class              = "STANDARD"
      public_access_prevention   = "inherited"
      soft_delete_retention_days = 7
      force_destroy              = false
    }

    migrate_sql_ayen_geo_map_int_manish_1 = {
      name                       = "migrate-sql-ayen-geo-map-int-manish-1"
      location                   = "me-west1"
      storage_class              = "STANDARD"
      public_access_prevention   = "inherited"
      soft_delete_retention_days = 7
      force_destroy              = false
    }

    research_manish = {
      name                       = "research_manish"
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

resource "random_password" "db_admin" {
  length  = 24
  special = false
}

resource "google_project_service" "required" {
  for_each = var.enable_project_services ? local.required_project_services : toset([])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_project_service" "network_required" {
  for_each = var.enable_project_services && local.network_project_id != var.project_id ? local.required_network_project_services : toset([])

  project            = local.network_project_id
  service            = each.value
  disable_on_destroy = false
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

  depends_on = [
    module.buckets
  ]
}

# Existing VPC used by both Cloud SQL private IP and the VM network interface.
# In Shared VPC this data source reads from the host project.
data "google_compute_network" "private_network" {
  project = local.network_project_id
  name    = var.network_name

  depends_on = [
    google_project_service.required,
    google_project_service.network_required
  ]
}

# Shared VPC subnet for the VM. Cloud SQL private IP uses the VPC peering range,
# while Compute Engine VM NICs should attach to an explicit regional subnet.
data "google_compute_subnetwork" "vm_subnet" {
  count = var.subnetwork_name == null ? 0 : 1

  project = local.network_project_id
  region  = var.subnetwork_region
  name    = var.subnetwork_name

  depends_on = [
    google_project_service.required,
    google_project_service.network_required
  ]
}

# Source image can live in another project or organization.
# The Terraform identity needs permission such as roles/compute.imageUser there.
data "google_compute_image" "vm_source" {
  project = var.vm_image_project_id
  name    = var.vm_image_name
  family  = var.vm_image_name == null ? var.vm_image_family : null

  lifecycle {
    postcondition {
      condition     = local.vm_image_is_set
      error_message = "Set either vm_image_name or vm_image_family."
    }
  }
}

# Cloud SQL private IP requires a reserved peering range for Service Networking.
resource "google_compute_global_address" "private_service_access" {
  project       = local.network_project_id
  name          = "${var.db_instance_name}-private-service-access"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.private_network.id

  depends_on = [
    google_project_service.required,
    google_project_service.network_required
  ]
}

# Creates the private services access connection used by Cloud SQL.
resource "google_service_networking_connection" "private_service_access" {
  network                 = data.google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}

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

  depends_on = [
    google_project_service.required
  ]
}

# VM boot disk is initialized from the cross-project image resolved above.
module "vm" {
  source = "./modules/compute_instance"

  project_id             = var.project_id
  name                   = var.vm_name
  zone                   = var.vm_zone
  machine_type           = var.vm_machine_type
  network_id             = data.google_compute_network.private_network.id
  subnetwork_id          = var.subnetwork_name != null ? data.google_compute_subnetwork.vm_subnet[0].self_link : null
  source_image           = data.google_compute_image.vm_source.self_link
  boot_disk_size_gb      = var.vm_boot_disk_size_gb
  boot_disk_type         = var.vm_boot_disk_type
  assign_public_ip       = var.vm_assign_public_ip
  tags                   = var.vm_tags
  labels                 = var.vm_labels
  service_account_email  = var.vm_service_account_email
  service_account_scopes = var.vm_service_account_scopes

  depends_on = [
    google_project_service.required
  ]
}

# PostgreSQL Cloud SQL instance, database, and SQL user.
module "postgres" {
  source = "./modules/cloud_sql_postgres"

  project_id          = var.project_id
  region              = var.region
  instance_name       = var.db_instance_name
  database_name       = var.db_name
  admin_user_name     = var.db_admin_user
  admin_user_password = local.db_admin_password
  tier                = var.db_tier
  disk_size_gb        = var.db_disk_size_gb
  availability_type   = var.db_availability_type
  deletion_protection = var.db_deletion_protection
  private_network_id  = data.google_compute_network.private_network.id
  enable_public_ip    = var.enable_public_ip
  authorized_networks = var.authorized_networks

  depends_on = [
    google_project_service.required,
    google_service_networking_connection.private_service_access
  ]
}

# PostGIS is a database extension, so it is managed with the PostgreSQL provider.
resource "postgresql_extension" "postgis" {
  name     = "postgis"
  database = module.postgres.database_name

  depends_on = [
    module.postgres
  ]
}
