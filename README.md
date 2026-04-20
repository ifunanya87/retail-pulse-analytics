# Retail Pulse Analytics

An end-to-end data engineering project analyzing wholesale liquor consumption and retail trends in Iowa using a Medallion Architecture.

---

## Problem Description

This project builds an automated pipeline to transform raw transaction data from Iowa's "controlled state" system into actionable business intelligence. The primary goals are:

- **Market Share Analysis:** Quantify vendor dominance across specific spirit categories (e.g., Whiskey vs. Tequila).
- **Risk Mitigation:** Identify operational anomalies where vendors exhibit statistically significant return rates compared to the market average.
- **Growth Tracking:** Visualize revenue trends to determine if the market is shifting toward premiumization or high-volume economy brands.
- **Operational Reproducibility:** Provide a 1-click execution environment (make pipeline) using Infrastructure as Code (Terraform) and modern orchestration (Dagster).

---

## Data Insights & Results

Based on the analysis of the Jan 2025 – June 2025 data scope, the following results were generated:

### 1. Performance Overview

- **Total Sales Revenue:** $203,163,494.  
  The market shows a steady upward trend from January through May, indicating strong consumer demand.

- **Actual Return Rate:** 0.09%.  
  While low, the "Actual" rate is used as a baseline to identify outliers.

- **Avg Market Share:** 2.85%.  
  This metric helps identify "Category Dominance," where top vendors significantly outperform the mean.

---

### 2. Category & Vendor Trends

- **Whiskey Dominance:** Whiskey remains the highest revenue category by a significant margin (approx. $65M+), followed by Vodka.

- **Market Leaders:** Diageo Americas and Sazerac Company lead the market in total revenue, both exceeding $35M in sales during the period.

- **Emerging Segments:** Liqueurs and Tequila show substantial mid-market volume, outpacing Gin and Brandy.

---

### 3. Anomaly Detection (The "Redline" Report)

- **Anomaly Count:** The system identified 156 anomalies requiring investigation.

- **Statistical Outliers:** Using a scatter plot mapping Revenue vs. Return Rate, we identified several vendors with return rates exceeding 15% - 30% despite having lower sales volumes.

  **What this means:** These vendors represent high operational risk. By flagging these, distributors can investigate product quality issues or shipping errors before they impact the bottom line of high-volume leaders like Diageo.

---

## Analytics Dashboard

![Iowa Liquor Sales Executive Summary](https://github.com/ifunanya87/retail-pulse-analytics/blob/main/images/Iowa%20Liquor%20Vendor%20Performance%20.png)
---

## Tech Stack

| Category       | Tool                  | Purpose                                                     |
|----------------|-----------------------|-------------------------------------------------------------|
| Cloud          | Google Cloud Platform | Managed infrastructure and storage (GCS & BigQuery)         |
| IaC            | Terraform             | Automated provisioning of cloud resources                   |
| Ingestion      | Dagster + dlt         | Orchestrated ingestion and schema management                |
| Warehouse      | BigQuery              | Optimized DWH with Time-Series Partitioning                 |
| Transformation | dbt                   | SQL modeling for Silver (Clean) and Gold (Reporting) layers |
| Visualization  | Streamlit             | Interactive A11y-compliant BI Dashboard                     |
| Automation     | Makefile              | 1-click end-to-end pipeline execution                       |
| **---**        | **---**               | **---**                                                     |

---

## Architecture

The pipeline follows a **Medallion Architecture pattern**:

- **Infrastructure:** Provisioned via Terraform.
- **Extract (Bronze):** Pulls 6 months of data from the SOCRATA API via dlt + dagster.
- **Load (Silver):** Initial cleaning and deduplication in BigQuery.
- **Transform (Gold):** dbt applies window functions to calculate Category Dominance Index, Rankings, and 95th Percentile Anomaly Flags.
- **Visualize:** Streamlit renders three tabs: Performance Overview, Category Trends, and the Anomaly Report.

---

## Data Warehouse Optimization

To ensure high performance and sub-second dashboard responsiveness despite 5+ years of transaction history, the warehouse implements a multi-layered **Partitioning and Clustering strategy**:

### 1. Native Partitioning (Cost Control)

- **Staging (Silver):**
  - Partitioned by `transaction_date` (Day).
  - Ensures that cleaning and deduplication tasks only scan the *new* daily data rather than the full history.

- **Intermediate & Gold:**
  - Partitioned by `partition_month` (Month).
  - Aligns with the primary BI use case (Month-over-Month growth).
  - Prevents "too many partitions" overhead while ensuring **Partition Pruning** on every dashboard query.

---

### 2. Strategic Clustering (Query Acceleration)

- **Join Keys:**
  - Tables are clustered by `invoice_id`.
  - Enables **colocated joins** between Sales and Geography models.
  - Significantly reduces shuffle cost during query execution.

- **Filter Dimensions:**
  - Gold tables are clustered by `vendor_name` and `category_name`.
  - These are primary slicers in the Streamlit dashboard.
  - Ensures BigQuery skips irrelevant data blocks entirely.

---

### 3. Incremental Strategy

- **Materialization:**
  - Marts use **incremental materialization** with an `insert_overwrite` strategy.

- **Lookback Window:**
  - A **2-month lookback window** is applied.
  - Captures late-arriving data and product returns without a full refresh.
  - Reduces processing costs by approximately **~90%**.

---

## Getting Started (Reproducibility)

This project is designed to be fully reproducible using GitHub Codespaces or a local DevContainer. All system dependencies are pre-configured.

### 1. Initialization

Use the provided GitHub Codespace or VS Code DevContainer to ensure all dependencies (Terraform, Python, uv) are pre-configured.

Once the container is started, use the following commands to verify the environment and initialize your cloud session:

1. [Create GCP cloud account and create IAM service account](#detailed-gcp-setup-guide)
2. Create an API token for Iowa Liquor sales data: [SOCRATA API](https://dev.socrata.com/foundry/data.iowa.gov/m3tr-qhgy)
3. Create a `.env` file based on `.env.example` (fill-in the TODOs)
4. Run the automated setup:

```bash
# Verify system tools (Terraform, Bruin, uv, gcp-cloud-cli) and sync Python libraries
make setup

# Authenticate with Google Cloud (ADC and CLI)
make auth-check
```
### 2. Execution

```bash
# Builds infrastructure using ADC auth and service iam impersonation
make apply
# Trigger batch run to extract and load data to gcs bucket, build bigquery warehouse via dbt, and visualize streamlit dashboard
make pipeline
```

### 3. Shutdown

```bash
# unsets gcloud auth/impersonate_service_account and unwanted artifacts
make clean
```

##### To destroy all cloud infrastructure (DANGEROUS)

```bash
make destroy
```
This command will permanently delete all Terraform-managed resources, including:
GCS buckets (raw data)
BigQuery datasets (Bronze, Silver, Gold)
Associated infrastructure (IAM, services, etc.)

**Use with caution**.


#### If setting the environment manually, then follow these steps

- **Download these tools locally:**
* **Google Cloud CLI** (v563.0.0+): For authentication and API management.
* **Terraform** (v1.14.8+): For Infrastructure as Code.
* **uv** (v0.11.3): For lightning-fast Python dependency management.
* **Docker** (v2.16.1): For building a dev container

- **Clone the repository**
- **Follow the initialization, execution, and shutdown steps**
---

## Detailed GCP Setup Guide

### Pre-requisite: 

1. **Create GCP account**: [Google Cloud Console](https://console.cloud.google.com/)
2. **Principal Permissions**

The **Principal Account** (the human user) **must** have the following administrative roles at the GCP Project level. 

| Role | Why it's needed |
| :--- | :--- |
| **Owner** | Provides full access to all resources; essential for initial infrastructure bootstrapping. |
| **Service Account Key Admin** | Allows the user to generate and download the `.json` key for local authentication. |
| **Service Usage Admin** | Required to enable BigQuery, GCS, and Resource Manager APIs automatically. |
| **Project Mover** | Necessary if the project needs to be migrated between folders or organizations. |
| **Organization Administrator** | Required for setting organization-level policies (if applicable). |


##### How to Verify Your Administrative Roles
* Open the **IAM & Admin** page in the [GCP Console](https://console.cloud.google.com/iam-admin/iam).
* Locate your email address in the **Principal** column.
* Ensure the roles listed above are active for your account. If they are missing, you will encounter "Permission Denied" errors during the `make apply` phase.


3. **Create and Assign IAM Service account roles**

* Manual Start: The user creates the Service Account manually in the GCP Console.
* Elevate: The user assigns the Owner role to that Service Account temporarily.
* Execute: 
```bash
# Terraform (acting as the Service Account) now has the authority to create the BigQuery datasets, the GCS buckets, and—most importantly—assign the fine-grained roles in your main.tf.
make apply
```
* Secure: Once Terraform is done, **remove the Owner role from the Service Account**. It will continue to function using only the specific permissions Terraform just granted it.

These are the fine grained roles terraform assigns to the Service Account using **IAM Conditions** for a restricted access only to project-specific resources.

| Category | Role Name | IAM Condition (Resource Name) | Scope / Allows |
| :--- | :--- | :--- | :--- | 
| **Infra** | `Storage Admin` | `resource.name.startsWith("projects/_/buckets/iowa-liquor-")` | Provision Landing Zone (LZ) bucket infrastructure. |
| **Infra** | `BigQuery Admin` | `resource.name.startsWith("projects/[ID]/datasets/iowa_liquor_")` | Configure Bronze, Silver, and Gold datasets. |
| **Infra** | `Storage Object Admin` | `resource.name == "projects/_/buckets/[STATE_BUCKET]"` | Read/Write for Terraform remote state backend. |
| **Data Flow** | `Storage Object Admin` | `resource.name == "projects/_/buckets/iowa-liquor-bronze"` | Authorize Bruin/dlt to ingest raw retail files. |
| **Data Flow** | `BQ Data Editor` | *None (Project Level)* | **dbt**: Perform DDL/DML and manage schemas. |
| **Execution** | `BQ Job User` | *None (Project Level)* | Initiate and run BigQuery query jobs. |
| **Usage** | `Usage Consumer` | *None (Project Level)* | Project-level API and quota consumption. |
| **---** | **---** | **---** | **---** |

> **Note:** `[ID]` stands for with an actual GCP Project ID while `[STATE_BUCKET]` represents the name of the bucket used to store your Terraform `.tfstate` file.

---
