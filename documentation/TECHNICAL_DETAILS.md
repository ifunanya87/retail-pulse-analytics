# Architecture

The pipeline follows a **Medallion Architecture pattern**:

- **Infrastructure:** Provisioned via Terraform.
- **Extract (Bronze):** Pulls 6 months of data from the SOCRATA API via dlt + dagster.
- **Load (Silver):** Initial cleaning and deduplication in BigQuery.
- **Transform (Gold):** dbt builds pre-aggregated marts and computes market intelligence metrics including vendor/category/store rankings, revenue share and HHI-based concentration, seasonality index, growth rates (MoM/YoY), and anomaly/churn risk flags.
- **Visualize:** Streamlit renders three tabs: Performance Overview, Category Trends, and the Anomaly Report.

## Medallion Layers

### Bronze Layer (Raw Ingestion)
- Raw transactional data ingested as-is  
- Ensures auditability and reproducibility  

### Silver Layer (Data Modeling)
- Cleaned and standardized datasets  
- Built core dimensions (dim_store, dim_date)  
- Enforced consistent joins, naming conventions, and time logic  
- Supports deeper analytical reconstruction when needed (e.g., penetration, segmentation logic)  

### Gold Layer (Analytics Marts)

Created business-facing models:

- agg_vendor_monthly_performance  
- agg_category_monthly_performance  
- agg_county_monthly_performance  
- agg_store_performance  
- fct_sales_performance  

These models are pre-aggregated analytical marts optimized for BI consumption, and power all Streamlit dashboards and insights.

---

# Data Warehouse Optimization

This warehouse is optimized for **time-series analytics at scale** using BigQuery-native partitioning, clustering, and precomputed marts.


## 1. Partitioning Strategy (Cost Control)

- **Silver Layer**
  - Partitioned by `transaction_date` (daily) for efficient incremental processing

- **Gold Layer**
  - Monthly grain (`sales_month`) aligned with BI use cases

- **Centralized `dim_date` enables:**
  - Consistent time logic  
  - Reliable MoM / YoY calculations  
  - Complete time series (including zero-activity periods)

>>Enables aggressive **partition pruning**, minimizing scan costs


## 2. Clustering Strategy (Query Performance)

- **Fact (`fct_sales_performance`)**
  - `vendor_name_standardized`, `category_group`, `county`

- **Marts optimized by access patterns:**
  - **Category:** `category_name_standardized`, `category_group`, `sales_month`
  - **Vendor:** `vendor_name_standardized`, `sales_month`
  - **County:** `county`, `sales_month`
  - **Store:** `county`, `store_id`

>>Ensures **block-level pruning** and fast dashboard filtering

## 3. Time-Series Modeling (Core Differentiator)

- Full **entity × month grids** (vendor, county) using `dim_date`
- Missing periods filled with **0 (not null)**

- **Window functions for:**
  - MoM / YoY growth  
  - Lag-based features  

- **Category mart includes SQL-based decomposition:**
  - Trend (rolling average)  
  - Seasonality (monthly baseline)  
  - Residuals (anomaly signal)  

- **Market structure metrics:**
  - Revenue share  
  - HHI (concentration)  

>>Enables forecasting, anomaly detection, and market analysis directly in SQL

## 4. Dataset-Aware Logic (Analytical Accuracy)

- Churn uses **dataset max date**, not system date  
- Time series start at **first observed activity** (no artificial padding)  
- `SAFE_DIVIDE` prevents invalid growth calculations  

>>Ensures **business-realistic metrics**

## 5. Materialization Strategy

- Gold models are **fully materialized tables**
- Heavy computations (windows, decomposition) are **precomputed**

>>**So dashboards feel instant, even on large datasets**
