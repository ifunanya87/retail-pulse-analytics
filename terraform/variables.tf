# Project Identification
variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "The default GCP region for resources"
  type        = string
}

# Security & Authentication
variable "tf_service_account" {
  description = "The Service Account email Terraform impersonates to create resources"
  type        = string
}

# Storage & Data Lake
variable "raw_bucket_name" {
  description = "The unique name for the GCS bucket acting as the Bronze landing zone"
  type        = string
}

# BigQuery Medallion Layers
variable "dataset_bronze" {
  description = "Dataset ID for raw, uncleaned Iowa liquor data"
  type        = string
}

variable "dataset_silver" {
  description = "Dataset ID for cleaned, standardized transaction data"
  type        = string
}

variable "dataset_gold" {
  description = "Dataset ID for business-ready analytical marts"
  type        = string
}
