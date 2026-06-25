provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Used only after Cloud SQL exists, to connect to PostgreSQL and enable PostGIS.
# When private IP is used, run Terraform from a network that can reach the VPC.
provider "postgresql" {
  host            = module.postgres.connection_host
  port            = 5432
  database        = module.postgres.database_names[var.db_provider_database_key]
  username        = module.postgres.user_names[var.db_provider_database_key]
  password        = local.db_passwords[var.db_provider_database_key]
  sslmode         = var.postgresql_sslmode
  connect_timeout = 15
  superuser       = false
}
