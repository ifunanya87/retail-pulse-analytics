# Retail Pulse Analytics

An end-to-end data engineering project analyzing 5 years of wholesale liquor consumption and retail trends in Iowa.

---

## Problem Description

The Iowa liquor market is a "controlled state" system, providing a transparent view of every wholesale transaction. This project builds an automated pipeline to analyze how socioeconomic factors and urban growth affect alcohol sales across Iowa's 99 counties to answer:

- **Volume vs. Value**: Are consumers shifting toward premium "Top-Shelf" spirits or high-volume economy brands in 2026?
- **Geospatial Hotspots**: Which counties (e.g., Polk vs. Linn) show the highest per-capita consumption growth?
- **Vendor Dominance**: Which suppliers (e.g., Diageo, Sazerac) are gaining market share in the growing "Ready-to-Drink" category?

---

## Getting Started (Reproducibility)

This project is designed to be fully reproducible using GitHub Codespaces or a local DevContainer. All system dependencies (Terraform, Bruin) and Python libraries are pre-configured.

### 1. Development Environment

The easiest way to run this project is to use the provided containerized environment:

- Option A (Cloud): Open this repository in a GitHub Codespace.

- Option B (Local): Open the folder in VS Code and click "Reopen in Container" when prompted (requires Docker).

### 2. Quick Start

Once the container is started, the environment is automatically initialized. You can verify the setup and sync dependencies using the Makefile:

```bash
# Verify system tools (Terraform, Bruin, uv) and sync Python libraries
make
```

### 3. Manual Setup (If not using Containers)

If you prefer to run this locally without Docker, you will need to:

- Install Terraform v1.14.8 and Bruin CLI.

- Install uv (Python package manager).

- Run the setup command:

```bash
make setup
```
---

![Work in Progress](https://img.shields.io/badge/status-in%20progress-1F4E79)

##### This project is currently under development. More details, code, and dashboards will be added soon. Stay tuned!
---


<!-- 
##  Tech Stack

| Category       | Tool                       | Purpose                                                        |
|----------------|----------------------------|----------------------------------------------------------------|
| Cloud          | Google Cloud Platform      | Managed infrastructure and storage                             |
| IaC            | Terraform                  | Automated provisioning of GCS and BigQuery resources          |
| Engine         | Bruin                      | Unified ingestion, SQL transformation, and orchestration      |
| Warehouse      | BigQuery                   | Serverless DWH with partitioning and clustering for optimization |
| Visualization  | Looker Studio              | Business intelligence dashboard for stakeholder storytelling  |

---

##  Architecture

The pipeline follows a **Medallion Architecture pattern**:

1. **Extract:** Python scripts (managed by Bruin) pull 5 years of data from Trading Economics.  
2. **Load (Bronze):** Raw data is stored in Google Cloud Storage (GCS) as the Data Lake.  
3. **Transform (Silver/Gold):** Bruin runs SQL transformations in BigQuery to clean data and calculate YoY growth.  
4. **Visualize:** The final Gold tables feed a Looker Studio dashboard.  

---

##  Data Warehouse Optimization

To ensure high performance and low query costs, the BigQuery tables are:

- **Partitioned by:** `month` (Time-series analysis is the primary use case)  
- **Clustered by:** `retail_sector` and `province` (To speed up filtered dashboard tiles)  

---

##  Getting Started (Reproducibility)

### 1. Prerequisites

- Google Cloud Project with a Service Account (JSON key)  
- Terraform installed  
- Bruin CLI installed:

```bash
curl -LsSf https://getbruin.com/install/cli | sh

-->
