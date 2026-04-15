# Core Project Info
output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}


# Storage (Bronze Layer)
output "raw_bucket_name" {
  description = "GCS bucket for raw (bronze) data"
  value       = google_storage_bucket.raw_data.name
}


# BigQuery Datasets
output "bronze_dataset_id" {
  description = "BigQuery Bronze dataset ID"
  value       = google_bigquery_dataset.bronze.dataset_id
}

output "silver_dataset_id" {
  description = "BigQuery Silver dataset ID"
  value       = google_bigquery_dataset.silver.dataset_id
}

output "gold_dataset_id" {
  description = "BigQuery Gold dataset ID"
  value       = google_bigquery_dataset.gold.dataset_id
}


# Fully Qualified Dataset References
output "bronze_dataset_fqdr" {
  description = "Fully qualified Bronze dataset"
  value       = "${var.project_id}.${google_bigquery_dataset.bronze.dataset_id}"
}

output "silver_dataset_fqdr" {
  description = "Fully qualified Silver dataset"
  value       = "${var.project_id}.${google_bigquery_dataset.silver.dataset_id}"
}

output "gold_dataset_fqdr" {
  description = "Fully qualified Gold dataset"
  value       = "${var.project_id}.${google_bigquery_dataset.gold.dataset_id}"
}
