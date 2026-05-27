/*
Model: agg_category_monthly_performance

Purpose:
This model aggregates liquor sales at a monthly category level to enable statewide market intelligence,
providing a business-ready view of category distribution patterns and state-level product movement to support BI,
forecasting, and strategic analysis.

This follows a 3-layer analytics engineering pattern:
1. Metrics Layer (raw aggregated KPIs)
2. Feature Engineering Layer (time-series features like lags & growth)
3. Decomposition Layer (trend, seasonality, residual modeling)

Grain:
One row per category_name_standardized × category_group × sales_month

Metrics:
- Total revenue (category popularity)
- Total volume sold
- Transaction count
- Month-over-month growth (%)
- Year-over-year growth (%)
- Trend component (smoothed revenue baseline)
- Seasonal index (month-of-year deviation from baseline)
- Expected revenue (trend × seasonality)
- Residual (unexplained variance after decomposition)

Note:
This model implements a SQL-based seasonal decomposition using rolling trend
and calendar seasonality approximations. Suitable for BI, anomaly detection,
and forecasting feature engineering.
*/


{{ config(
    materialized='table',
    schema='liquor_gold',
    cluster_by=['category_name_standardized', 'category_group', 'sales_month']
) }}


-- Metrics
with monthly_metrics as (
    select
        sales_month,
        category_name_standardized,
        category_group,

        sum(revenue) as total_revenue,
        sum(volume_liters_sold) as total_volume,
        count(distinct invoice_id) as transaction_count

    from {{ ref('fct_sales_performance') }}

    group by 1, 2, 3
),


-- Feature engineering (time-series features)
features as (
    select
        *,

        -- previous month revenue
        lag(total_revenue) over(
            partition by category_group, category_name_standardized
            order by sales_month
        ) as prev_month_revenue,

        -- previous year revenue
        lag(total_revenue, 12) over(
            partition by category_group, category_name_standardized
            order by sales_month
        ) as prev_year_revenue,

        -- MoM growth %
        safe_divide(
            total_revenue - lag(total_revenue) over(
                partition by category_group, category_name_standardized
                order by sales_month
            ),
            lag(total_revenue) over(
                partition by category_group, category_name_standardized
                order by sales_month
            )
        ) as mom_growth_pct,

        -- YoY growth %
        safe_divide(
            total_revenue - lag(total_revenue, 12) over(
                partition by category_group, category_name_standardized
                order by sales_month
            ),
            lag(total_revenue, 12) over(
                partition by category_group, category_name_standardized
                order by sales_month
            )
        ) as yoy_growth_pct

    from monthly_metrics
),


-- Decomposition (trend + seasonality + residual)
trend_component as (
    select
        *,

        -- Trend: 3-month moving average (smooth baseline)
        avg(total_revenue) over (
            partition by category_group, category_name_standardized
            order by sales_month
            rows between 2 preceding and current row
        ) as trend_revenue

    from features
),

seasonality_component as (
    select
        *,

        extract(month from sales_month) as month_of_year,

        -- Seasonal baseline across years
        avg(total_revenue) over (
            partition by category_group, category_name_standardized, extract(month from sales_month)
        ) as avg_month_revenue

    from trend_component
),

decomposition_base as (
    select
        *,
        -- overall category baseline
        avg(total_revenue) over (
            partition by category_group, category_name_standardized
        ) as overall_avg_revenue
    from seasonality_component
),

decomposition as (
    select
        *,
        -- seasonal index
        safe_divide(avg_month_revenue, overall_avg_revenue) as seasonal_index,
        -- expected value = trend × seasonality
        trend_revenue * safe_divide(avg_month_revenue, overall_avg_revenue) as expected_revenue,
        -- residual = actual - expected
        total_revenue - (
            trend_revenue * safe_divide(avg_month_revenue, overall_avg_revenue)
        ) as residual_revenue
    from decomposition_base
)

-- Final
select
    sales_month,
    category_name_standardized,
    category_group,

    total_revenue,
    total_volume,
    transaction_count,

    prev_month_revenue,
    prev_year_revenue,

    mom_growth_pct,
    yoy_growth_pct,

    trend_revenue,
    seasonal_index,
    expected_revenue,
    residual_revenue

from decomposition
