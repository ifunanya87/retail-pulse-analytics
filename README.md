# Retail Pulse Analytics: Canadian Economic Resilience (2021–2026) 

An end-to-end **data engineering project** analyzing 5 years of Canadian retail and economic trends.

---

## Problem Description

The Canadian retail landscape has faced significant volatility from 2021 to 2026, influenced by post-pandemic recovery, high inflation, and shifting interest rates. This project builds an **automated pipeline** to ingest, transform, and visualize retail sales data to answer:

- **Essential vs. Discretionary:** Are Canadians cutting back on groceries to afford "big-ticket" items like motor vehicles?  
- **Regional Dominance:** Which provinces (e.g., Alberta vs. Ontario) are leading the economic recovery?  
- **The E-commerce Shift:** Is digital trade continuing to grow as a percentage of total retail turnover in 2026?  

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
