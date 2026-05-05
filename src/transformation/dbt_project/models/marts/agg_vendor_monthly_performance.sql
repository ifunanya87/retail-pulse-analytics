/*
Model: agg_vendor_monthly_performance
Layer: Gold (Marts)

Purpose:
This model aggregates liquor distribution data at a monthly vendor level to analyze
supply-side structure within Iowa’s regulated alcohol distribution system. It captures
vendor contribution to total system throughput, distribution footprint over time, and
temporal shifts in supply concentration.

It supports market intelligence focused on supply dynamics rather than
consumer demand or competitive retail performance.

Additionally, the model computes a Herfindahl-Hirschman Index (HHI) to quantify
system-wide supply concentration at the monthly level, enabling analysis of how
distribution dominance evolves over time.

The model also uses a date spine to ensure continuous monthly time series per vendor,
enabling accurate MoM and YoY calculations even when vendors have intermittent activity.

Grain:
One row per vendor_name_standardized × sales_month
*/

{{ config(
    materialized='table',
    schema='liquor_gold',
    cluster_by=['vendor_name_standardized', 'sales_month']
) }}

-- Date spine (monthly) sourced from dim_date
with date_spine as (
    select distinct
        month_start_date as sales_month
    from {{ ref('dim_date') }}
    where date_day between (
        select min(transaction_date) from {{ ref('fct_sales_performance') }}
    )
    and (
        select max(transaction_date) from {{ ref('fct_sales_performance') }}
    )
),

-- Optimized grid (FULL VENDOR × FULL TIME SPINE)
vendor_month_grid as (
    select
        v.vendor_name_standardized,
        d.sales_month
    from (
        select distinct vendor_name_standardized
        from {{ ref('fct_sales_performance') }}
        where vendor_name_standardized is not null
    ) v
    cross join date_spine d
),

-- Metrics
monthly_metrics as (
    select
        date_trunc(transaction_date, month) as sales_month,
        vendor_name_standardized,

        sum(revenue) as total_revenue,
        sum(volume_liters_sold) as total_volume,
        count(distinct invoice_id) as transaction_count

    from {{ ref('fct_sales_performance') }}

    where vendor_name_standardized is not null

    group by 1, 2
),

-- Join grid with actuals (to fill gaps)
filled_metrics as (
    select
        g.sales_month,
        g.vendor_name_standardized,

        coalesce(m.total_revenue, 0) as total_revenue,
        coalesce(m.total_volume, 0) as total_volume,
        coalesce(m.transaction_count, 0) as transaction_count

    from vendor_month_grid g
    left join monthly_metrics m
        on g.sales_month = m.sales_month
        and g.vendor_name_standardized = m.vendor_name_standardized
),

-- Market_total (used as denominator for contribution)
monthly_totals as (
    select
        sales_month,
        sum(total_revenue) as state_total_revenue,
        sum(total_volume) as state_total_volume
    from filled_metrics
    group by 1
),

-- Window features
window_features as (
    select
        *,

        lag(total_revenue) over (
            partition by vendor_name_standardized
            order by sales_month
        ) as prev_month_revenue,

        lag(total_revenue, 12) over (
            partition by vendor_name_standardized
            order by sales_month
        ) as prev_year_revenue

    from filled_metrics
),

-- Contribution + features
features as (
    select
        w.*,

        t.state_total_revenue,
        t.state_total_volume,

        safe_divide(w.total_revenue, t.state_total_revenue) as revenue_share,
        safe_divide(w.total_volume, t.state_total_volume) as volume_share,

        safe_divide(
            w.total_revenue - w.prev_month_revenue,
            w.prev_month_revenue
        ) as mom_growth_pct,

        safe_divide(
            w.total_revenue - w.prev_year_revenue,
            w.prev_year_revenue
        ) as yoy_growth_pct

    from window_features w
    left join monthly_totals t
        on w.sales_month = t.sales_month
),

-- Concentration proxy (vendor-level)
concentration as (
    select
        *,
        power(revenue_share, 2) as revenue_share_squared
    from features
),

-- HHI (market-level concentration)
hhi_index as (
    select
        sales_month,
        sum(revenue_share_squared) as hhi_index
    from concentration
    group by sales_month
),

-- Final
final as (
    select
        c.*,
        h.hhi_index
    from concentration c
    left join hhi_index h
        on c.sales_month = h.sales_month
)

select
    sales_month,
    vendor_name_standardized,

    total_revenue,
    total_volume,
    transaction_count,

    state_total_revenue,
    state_total_volume,

    revenue_share,
    volume_share,

    prev_month_revenue,
    prev_year_revenue,
    mom_growth_pct,
    yoy_growth_pct,

    revenue_share_squared,
    hhi_index

from final
