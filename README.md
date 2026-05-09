# Retail Pulse Analytics

An end-to-end data engineering project analyzing wholesale liquor consumption and retail trends in Iowa using a Medallion Architecture.

## Problem Description

This project implements a production-grade Medallion architecture to transform Iowa’s liquor transaction data into a multi-dimensional market intelligence platform. Rather than stopping at aggregation, the system builds a structured analytical layer that explains why performance changes across time, geography, vendors, and product categories.

It delivers five core analytical lenses:


### 1. Market Structure & Power Dynamics

Identify dominant vendors, market concentration, and shifts in competitive control using:

- revenue_share  
- hhi_index  

from vendor and county aggregated marts.


### 2. Geographic & Operational Intelligence

Analyze county and store-level performance to uncover demand clusters, distribution gaps, and early signals of store underperformance using:

- total_revenue  
- mom_growth_pct  
- hhi_index  
- churn_risk_flag (store-level signal from Gold mart)  


### 3. Product Behavior & Seasonality

Track category-level trends using:

- total_revenue  
- yoy_growth_pct  
- seasonal_index  

to distinguish structural growth from cyclical demand patterns.

### 4. Revenue Efficiency & Pricing Power

Evaluate monetization efficiency across categories, vendors, and stores using:

- total_revenue  
- total_volume  
- avg_order_value  
- revenue_per_active_day  

This reveals whether growth is driven by volume expansion or pricing efficiency, highlighting premium vs mass-market behavior.

### 5. Market Momentum & Acceleration

Compare:

- mom_growth_pct  
- yoy_growth_pct  

to detect:

- accelerating growth segments  
- decelerating categories  
- early-stage expansion signals  

This enables forward-looking demand intelligence rather than static reporting.

---

## Data-as-Code Philosophy

The platform is built using a modern, reproducible data stack:

- Terraform → reproducible infrastructure  
- Dagster → orchestrated data workflows  
- dbt → modular, testable transformation layer  

---

## Solution Architecture

I designed a Medallion Architecture (Bronze → Silver → Gold) to progressively refine data into business-ready insights.

For deep dives into technical implementation, refer to:

* [**Technical Architecture & Deep Dive**](./documentation/TECHNICAL_DETAILS.md)

---

## Data Insights & Results

Analysis was conducted on **Jan 2025 – June 2025**, focusing on normalized trends, distribution patterns, market structure, operational efficiency, and forward-looking market signals.

---

### 1. Market Performance & Growth Dynamics

* **Total Sales Revenue:** $202,975,123  
* **Total Volume (Liters):** 10,732,491  
* **Avg Unit Price:** $20.45  

The market shows steady growth through Q2, supported by both increasing sales revenue and strong product volume. The **Revenue Trend (Daily vs. 7-Day Moving Average)** helps smooth out short-term fluctuations and shows that the upward trend is fairly consistent over time instead of being caused by a few isolated spikes.

Revenue growth also remains strong while average pricing stays relatively stable, which suggests that the increase is being driven more by customer demand and product mix performance than by price inflation alone.

---

### 2. Category Intelligence (Demand vs. Seasonality)

* **Whiskey (Structural Anchor):** Identified as the Top Performing Category with an Avg MoM Growth of 5.05%.  
* **Vodka (Stable Core):** Functions as the second-largest revenue pillar with high volume and low volatility.  
* **Growth Quality Insight:** The Category MoM Growth Heatmap identifies specific acceleration periods, with categories like "Special" and "Mezcal" showing high-intensity growth bursts.  

The category analysis shows a mix of stable high-volume products and smaller fast-growing segments. Whiskey stands out because it combines strong sales volume with consistent month-over-month growth, while Vodka remains one of the more stable categories with lower volatility.

Smaller categories such as "Special" and "Mezcal" show sharper growth increases during certain periods, which may indicate changing customer preferences or growing interest in premium products. Even though these categories are smaller, their growth patterns could become more important over time if the trend continues.

---

### 3. Vendor Landscape & Market Concentration

* **Top Vendors:** Diageo Americas and Sazerac Company dominate the revenue share.  
* **Concentration Insight:** A Market Concentration (HHI) of 0.096 confirms a moderately concentrated supplier market.  
* **Long-Tail Structure:** The cumulative revenue curve illustrates that while a small number of vendors control the majority of revenue, a fragmented supplier ecosystem exists in the long tail.  

The vendor landscape shows that a few large suppliers control a major portion of total revenue, while many smaller vendors still contribute to the broader market. The HHI value suggests the market is moderately concentrated rather than fully dominated by only a handful of companies.

The long-tail structure also highlights the complexity of the supplier ecosystem, since many smaller vendors collectively still account for a noticeable share of the market despite having lower individual sales volumes.

---

### 4. Geographic & Store-Level Performance

* **County Variability:** Polk County stands as the leading revenue contributor in the state.  
* **Market Coverage:** The pipeline successfully processes data across 99/99 Iowa counties with a minimal Revenue Attribution Leakage of 0.03%.  
* **Store Segmentation:** Using K-Means clustering, the system segments 2,125 active stores into performance tiers based on revenue and volume.  

The geographic analysis shows that demand is not evenly distributed across the state, with Polk County contributing the highest revenue overall. Processing all 99 counties with very low attribution leakage also confirms that the pipeline maintains strong coverage and data consistency.

The K-Means clustering model groups stores into different performance levels based on sales behavior and volume. This makes it easier to identify high-performing stores, mid-tier stores, and stores that may require closer operational review.

---

### 5. Risk & Operational Signals

* **Store Risk:** The system identified 1,566 High Risk Stores (labeled as -Critical).  
* **Underperforming Store List:** The Gold layer generates a variance-based list, highlighting stores like "Fareway Stores #941" and "Casey's General Store #3220" that significantly deviate from expected performance.  

The risk analysis focuses on stores that perform below expected patterns rather than simply looking at low revenue alone. By measuring performance variance, the system can highlight locations that may be affected by declining demand, operational inefficiencies, or regional market pressure.

The relatively high number of high-risk stores suggests that performance instability is spread across many parts of the retail network rather than being limited to only a few stores.

---

### 6. Revenue Efficiency & Pricing Power

* **Portfolio Efficiency:** The system calculates an Avg Portfolio Efficiency of $21.91/L.  
* **Store-Level Efficiency:** Top 10 rankings reveal highly efficient outliers, such as Hy-Vee Fast & Fresh Express - Osceola, which generates $629.92/L, indicating high-margin product mixes.  

The efficiency analysis measures how effectively stores convert product volume into revenue. While the overall portfolio efficiency remains fairly stable, some stores generate much higher revenue per liter than others.

These outlier stores may be benefiting from premium product mixes, stronger local demand, or more optimized inventory selection. Identifying these patterns can help explain where pricing power and higher-margin performance are strongest.

---

### 7. Market Momentum & Acceleration

* **Momentum Identification:** Using MoM Growth %, we identify "Special" and "Rum" as top-growing categories.  
* **Acceleration Heatmap:** This visualization enables forward-looking intelligence by tracking the velocity of growth across different sales months.  

The momentum analysis focuses more on growth speed than total market size. Categories with strong acceleration may become more important over time even if they are not currently the largest contributors to total revenue.

The acceleration heatmap helps track when growth is increasing or slowing down across different periods, making it easier to spot emerging trends and changing market behavior earlier.

---

### Key Takeaway

This system transforms raw liquor transaction data into a scalable Retail Intelligence Platform, where:

* Vendors are analyzed through revenue share concentration and HHI-based market structure metrics.  
* Categories are evaluated through seasonality, normalized growth trends, and acceleration behavior.  
* Stores are segmented using behavioral clustering, revenue efficiency, and variance-based risk analysis.  
* Counties expose geographic demand concentration across all 99 Iowa regions.  
* Momentum Layers provide forward-looking intelligence capable of identifying emerging commercial trends before full market maturation.  

Overall, the platform goes beyond basic reporting by combining scalable data engineering with analytical models that help explain market behavior across vendors, categories, stores, and geographic regions.

All insights are derived strictly from Gold marts and minimal Silver dimensions (`dim_store`, `dim_date`), ensuring reproducibility, governance consistency, and BI-grade analytical reliability.

---

## Analytics Dashboard

![Iowa Liquor Sales Executive Summary]()
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

## Getting Started (Reproducibility)

This project is designed to be fully reproducible using GitHub Codespaces or a local DevContainer. All system dependencies are pre-configured.

### 1. Initialization

Use the provided GitHub Codespace or VS Code DevContainer to ensure all dependencies (Terraform, Python, uv) are pre-configured.

Once the container is started, use the following commands to verify the environment and initialize your cloud session:

1. [**Create GCP cloud account and create IAM service account**](./documentation/GCP_SETUP_GUIDE.md)
2. Create an API token for Iowa Liquor sales data: [**SOCRATA API**](https://dev.socrata.com/foundry/data.iowa.gov/m3tr-qhgy)
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
