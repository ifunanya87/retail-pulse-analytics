terraform {
  backend "gcs" {} 
}

provider "google" {
  project                     = var.project_id
  region                      = var.region
  impersonate_service_account = var.tf_service_account
}


# # IAM SERVICE ACCOUNT role assignments
# # Storage Admin with Condition (Infra)
# resource "google_project_iam_member" "storage_admin" {
#   project = var.project_id
#   role    = "roles/storage.admin"
#   member  = "serviceAccount:${var.tf_service_account}"

#   condition {
#     title       = "restrict_to_iowa_liquor_buckets"
#     description = "Allows provisioning only for iowa-liquor related buckets"
#     expression  = "resource.name.startsWith(\"projects/_/buckets/iowa-liquor-\")"
#   }
# }

# # BigQuery Admin with Condition (Infra)
# resource "google_project_iam_member" "bq_admin" {
#   project = var.project_id
#   role    = "roles/bigquery.admin"
#   member  = "serviceAccount:${var.tf_service_account}"

#   condition {
#     title       = "restrict_to_iowa_liquor_datasets"
#     description = "Allows configuration of medallion datasets"
#     expression  = "resource.name.startsWith(\"projects/${var.project_id}/datasets/iowa_liquor_\")"
#   }
# }

# # BigQuery Data Editor (Data Flow - Project Level)
# resource "google_project_iam_member" "bq_data_editor" {
#   project = var.project_id
#   role    = "roles/bigquery.dataEditor"
#   member  = "serviceAccount:${var.tf_service_account}"
# }

# # BigQuery Job User (Execution - Project Level)
# resource "google_project_iam_member" "bq_job_user" {
#   project = var.project_id
#   role    = "roles/bigquery.jobUser"
#   member  = "serviceAccount:${var.tf_service_account}"
# }

# # Service Usage Consumer (Usage - Project Level)
# resource "google_project_iam_member" "usage_consumer" {
#   project = var.project_id
#   role    = "roles/serviceusage.serviceUsageConsumer"
#   member  = "serviceAccount:${var.tf_service_account}"
# }

# # Storage Object Admin for specific bucket (Data Flow)
# resource "google_storage_bucket_iam_member" "bronze_object_admin" {
#   bucket = google_storage_bucket.raw_data.name
#   role   = "roles/storage.objectAdmin"
#   member = "serviceAccount:${var.tf_service_account}"
# }


# Medallion Architecture Datasets (50-Day TTL)
resource "google_bigquery_dataset" "bronze" {
  dataset_id                  = var.dataset_bronze
  location                    = var.region
  default_table_expiration_ms = 4320000000 
  labels = { layer = "bronze", env = "capstone" }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigquery_dataset" "silver" {
  dataset_id                  = var.dataset_silver
  location                    = var.region
  default_table_expiration_ms = 4320000000 
  labels = { layer = "silver", env = "capstone" }
}

resource "google_bigquery_dataset" "gold" {
  dataset_id                  = var.dataset_gold
  location                    = var.region
  default_table_expiration_ms = 4320000000 
  labels = { layer = "gold", env = "capstone" }
}

# Dedicated Dataset for dbt Snapshots (SCD Type 2 tracking)
resource "google_bigquery_dataset" "snapshots" {
  dataset_id                  = var.dataset_snapshots
  location                    = var.region
  default_table_expiration_ms = 4320000000
  labels = { layer = "snapshots", env   = "capstone" }
}



# Secure Landing Zone
resource "google_storage_bucket" "raw_data" {
  name                        = var.raw_bucket_name
  location                    = var.region
  force_destroy               = true
  
  # Enforce IAM-only permissions
  uniform_bucket_level_access = true 

  lifecycle {
    prevent_destroy = true
  }

  lifecycle_rule {
    condition { age = 50 }
    action    { type = "Delete" }
  }
}
