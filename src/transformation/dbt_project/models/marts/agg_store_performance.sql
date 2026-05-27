/*
    Model: agg_store_performance
    Layer: Gold (Marts)
    Grain: One row per Store ID

    Description:
    - Retail endpoint activity within Iowa’s regulated liquor distribution system
    - Aggregates transaction volume, revenue throughput, and ordering intensity at the store level
    - Captures store-level distribution consumption patterns (not customer behavior)
    - Repeat purchase intensity is a proxy metric derived from transaction frequency due to absence of customer-level data
    - Inactivity-based churn represents distribution dormancy, not customer churn
    - Includes churn classification (Active / At-Risk / Churned) based on dataset-anchored inactivity thresholds
    - Dataset-context aware and optimized for BI dashboards and operational monitoring of retail endpoints
*/

{{ config(
    materialized='table',
    cluster_by=["county", "store_id"]
) }}

with base as (
    select 
        {{ dbt_utils.star(from=ref('fct_sales_performance'), except=["sales_month"]) }}
    from {{ ref('fct_sales_performance') }}
),

-- Dataset anchor date
dataset_context as (
    select
        max(transaction_date) as dataset_max_date
    from base
),

-- Aggregate facts
store_aggregates as (

    select
        store_id,

        -- Core volume metrics
        count(distinct invoice_id) as total_transactions,
        sum(revenue) as total_revenue,
        sum(bottles_sold) as total_bottles_sold,
        sum(volume_liters_sold) as total_volume_liters,

        -- Time
        min(transaction_date) as first_purchase_date,
        max(transaction_date) as last_purchase_date,
        count(distinct transaction_date) as active_days,

        -- Revenue efficiency
        safe_divide(sum(revenue), count(distinct invoice_id)) as avg_order_value,
        safe_divide(sum(revenue), count(distinct transaction_date)) as revenue_per_active_day,

        -- Behavioral metrics
        safe_divide(count(distinct invoice_id), count(distinct transaction_date)) 
            as avg_transactions_per_day,

        -- Repeat purchase 
        case 
            when count(distinct transaction_date) > 0 then
                safe_divide(count(distinct invoice_id), count(distinct transaction_date))
            else null
        end as repeat_purchase_intensity,

        -- Product diversity
        count(distinct category_group) as category_diversity,
        count(distinct vendor_name_standardized) as vendor_diversity,

        -- FIXED: dataset-anchored inactivity (NOT system date)
        date_diff(
            (select dataset_max_date from dataset_context),
            max(transaction_date),
            day
        ) as inactivity_days

    from base
    group by 1
),

-- From SCD2 dimension
current_store as (
    select
        store_id,
        store_name,
        county,
        city
    from {{ ref('dim_store') }}
    where is_current = true
),

store_level as (

    select
        s.store_id,
        s.store_name,
        s.county,
        s.city,

        a.total_transactions,
        a.total_revenue,
        a.total_bottles_sold,
        a.total_volume_liters,

        a.first_purchase_date,
        a.last_purchase_date,
        a.active_days,

        a.avg_order_value,
        a.revenue_per_active_day,
        a.avg_transactions_per_day,
        a.repeat_purchase_intensity,

        a.category_diversity,
        a.vendor_diversity,

        a.inactivity_days,

        -- Churn classification (dataset-aware)
        case
            when a.inactivity_days is null then 'NO_ACTIVITY'
            when a.inactivity_days <= 30 then 'ACTIVE'
            when a.inactivity_days <= 60 then 'AT_RISK_30_60'
            when a.inactivity_days <= 90 then 'AT_RISK_60_90'
            else 'CHURNED_90_PLUS'
        end as churn_status,

        -- Numeric buckets (for BI tool)
        case
            when a.inactivity_days is null then 0
            when a.inactivity_days <= 30 then 1
            when a.inactivity_days <= 60 then 2
            when a.inactivity_days <= 90 then 3
            else 4
        end as churn_stage

    from current_store s
    left join store_aggregates a
        on s.store_id = a.store_id
)

select *
from store_level
