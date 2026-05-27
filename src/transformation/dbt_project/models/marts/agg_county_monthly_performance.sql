/*
Model: agg_county_monthly_performance
Layer: Gold (Marts)

Purpose:
This model builds a complete monthly view of liquor sales performance across Iowa counties.
Instead of just aggregating transactions, it creates a full county × month time series so that
inactive periods are explicitly captured as zeros. This makes it possible to analyze real trends
over time, including growth, seasonality, and changes in geographic concentration.

It is mainly used for understanding how distribution activity shifts across counties and how
each region contributes to the overall state-level performance.

Grain:
One row per county × sales_month

How it works:
- Creates a complete county-by-month grid using a generated date spine and cross join
- Joins transactional sales data onto this grid
- Fills missing county-month combinations with zero activity
- Builds state-level totals from the completed dataset (after filling gaps)
- Uses window functions to calculate month-over-month and year-over-year trends

Key metrics:
- total_revenue: Total sales revenue per county per month
- total_volume: Total liters sold per county per month
- transaction_count: Number of invoices per county per month
- active_stores: Number of unique stores active in that county per month

- revenue_share: Share of state revenue contributed by each county
- volume_share: Share of state volume contributed by each county

- mom_growth_pct: Month-over-month revenue growth
- yoy_growth_pct: Year-over-year revenue growth (12-month comparison)

- hhi_index: State-level concentration score (Herfindahl index), showing how concentrated
  sales are across counties in a given month

Assumptions:
- Missing county-month combinations are treated as zero activity, not nulls
- Growth rates can be null when the previous period has zero revenue
- County list is derived dynamically from the fact table, not a static dimension
- State totals are calculated after filling the full time-series grid

What this model is good for:
- Tracking regional performance over time
- Understanding which counties drive state revenue
- Detecting shifts in concentration or dispersion across the state
- Analyzing growth trends at a geographic level
*/

{{ config(
    materialized='table',
    schema='liquor_gold',
    cluster_by=['county', 'sales_month']
) }}

-- Date spine (monthly)
with date_spine as (
    select distinct
        month_start_date as sales_month
    from {{ ref('dim_date') }}
    where month_start_date between
        (select min(date_trunc(transaction_date, month)) from {{ ref('fct_sales_performance') }})
        and
        (select max(date_trunc(transaction_date, month)) from {{ ref('fct_sales_performance') }})
),

-- County dimension (from store dimension inside fact)
county_dim as (
    select distinct
        county
    from {{ ref('fct_sales_performance') }}
    where county is not null
),

-- County × Month grid (no explosion, stable dimension join)
county_month_grid as (
    select
        c.county,
        d.sales_month
    from county_dim c
    cross join date_spine d
),

-- Monthly county metrics
monthly_metrics as (
    select
        sales_month,
        county,

        sum(revenue) as total_revenue,
        sum(volume_liters_sold) as total_volume,
        count(distinct invoice_id) as transaction_count,
        count(distinct store_id) as active_stores

    from {{ ref('fct_sales_performance') }}
    where county is not null
    group by 1, 2
),

-- Fill missing months per county
filled_metrics as (
    select
        g.sales_month,
        g.county,

        coalesce(m.total_revenue, 0) as total_revenue,
        coalesce(m.total_volume, 0) as total_volume,
        coalesce(m.transaction_count, 0) as transaction_count,
        coalesce(m.active_stores, 0) as active_stores

    from county_month_grid g
    left join monthly_metrics m
        on g.sales_month = m.sales_month
        and g.county = m.county
),

-- State totals (for contribution analysis)
monthly_state_totals as (
    select
        sales_month,
        sum(total_revenue) as state_total_revenue,
        sum(total_volume) as state_total_volume
    from filled_metrics
    group by 1
),

-- Window features (county-level time series behavior)
window_features as (
    select
        *,
        lag(total_revenue) over (
            partition by county
            order by sales_month
        ) as prev_month_revenue,

        lag(total_revenue, 12) over (
            partition by county
            order by sales_month
        ) as prev_year_revenue

    from filled_metrics
),

-- Seasonality baseline (monthly pattern across all years)
seasonality_baseline as (
    select
        extract(month from sales_month) as month_num,
        avg(total_revenue) as avg_monthly_revenue
    from filled_metrics
    group by 1
),

-- Feature engineering
features as (
    select
        w.*,
        s.state_total_revenue,
        s.state_total_volume,

        sb.avg_monthly_revenue,

        -- Geographic contribution
        safe_divide(w.total_revenue, s.state_total_revenue) as revenue_share,
        safe_divide(w.total_volume, s.state_total_volume) as volume_share,

        -- Growth dynamics
        safe_divide(
            w.total_revenue - w.prev_month_revenue,
            w.prev_month_revenue
        ) as mom_growth_pct,

        safe_divide(
            w.total_revenue - w.prev_year_revenue,
            w.prev_year_revenue
        ) as yoy_growth_pct,

        -- Seasonality index (baseline normalization)
        safe_divide(
            w.total_revenue,
            sb.avg_monthly_revenue
        ) as seasonality_index

    from window_features w
    left join monthly_state_totals s
        on w.sales_month = s.sales_month
    left join seasonality_baseline sb
        on extract(month from w.sales_month) = sb.month_num
),

-- Concentration proxy at county level
concentration as (
    select
        *,
        power(revenue_share, 2) as revenue_share_squared
    from features
),

-- Optional: spatial concentration index (state-wide per month)
hhi_index as (
    select
        sales_month,
        sum(revenue_share_squared) as hhi_index
    from concentration
    group by sales_month
),

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
    county,

    -- Activity
    total_revenue,
    total_volume,
    transaction_count,
    active_stores,

    -- System context
    state_total_revenue,
    state_total_volume,

    -- Geographic contribution
    revenue_share,
    volume_share,

    -- Dynamics
    prev_month_revenue,
    prev_year_revenue,
    mom_growth_pct,
    yoy_growth_pct,

    -- Seasonality
    seasonality_index,

    -- Concentration signals
    revenue_share_squared,
    hhi_index

from final
