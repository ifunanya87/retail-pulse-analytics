terraform {
  backend "gcs" {} 
}

provider "google" {
  project                     = var.project_id
  region                      = var.region
  impersonate_service_account = var.tf_service_account
}



# Medallion Architecture Datasets (50-Day TTL)
resource "google_bigquery_dataset" "bronze" {
  dataset_id                  = var.dataset_bronze
  location                    = var.region
  default_table_expiration_ms = 4320000000 
  labels = { layer = "bronze", env = "capstone" }
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



# Secure Landing Zone
resource "google_storage_bucket" "raw_data" {
  name                        = var.raw_bucket_name
  location                    = var.region
  force_destroy               = true
  
  # Enforce IAM-only permissions
  uniform_bucket_level_access = true 

  lifecycle_rule {
    condition {
      age = 50 
    }
    action {
      type = "Delete"
    }
  }
}
