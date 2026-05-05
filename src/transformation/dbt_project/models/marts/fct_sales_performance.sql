/*
    Model: fct_sales_performance
    Layer: Gold (Marts)

    Description:
    - Central fact table representing state-level liquor distribution transactions
    - Atomic grain: one row per invoice (transaction event)
    - Serves as the system-of-record for downstream analytical marts (category, vendor, store)
    - Captures distribution flows across vendors, product categories, and retail endpoints
    - Designed as a foundation layer for aggregation, time-series analysis, and market intelligence modeling
*/

{{ config(
    materialized='table',
    cluster_by=["vendor_name_standardized", "category_group", "county"]
) }}

with standardized_sales as (
    select * from {{ ref('int_iowa_liquor__sales_standardized') }}
)

select
    -- Primary Key
    invoice_id,
    
    -- Temporal Dimensions
    transaction_date,
    extract(year from transaction_date) as calendar_year,
    extract(month from transaction_date) as calendar_month,
    
    -- Entity Keys (Standardized in Silver)
    vendor_name_standardized,
    category_name_standardized,
    category_group,
    spirit_type,
    
    -- Location & Retailer Info
    store_id,
    store_name,
    county,
    city,

    -- Item Info
    item_id,
    item_description,

    -- Quantitative Metrics
    bottles_sold,
    revenue,
    volume_liters_sold,
    volume_gallons_sold,
    
   -- Calculated Performance Metrics
    safe_divide(revenue, volume_liters_sold) as price_per_liter,
    safe_divide(revenue, bottles_sold) as avg_unit_price

from standardized_sales
