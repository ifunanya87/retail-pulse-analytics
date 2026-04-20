/*
    Model: dm_vendor_performance_reporting
    Layer: Gold (Reporting Mart)
    Description: 
    - Enriches the monthly base fact with competitive window functions.
    - Calculates Market Share (Dominance), Ranking, and Anomaly Detection.
    - Materialized as a view for real-time analysis on top of the fact table.
*/

{{ config(materialized='view') }}

with base_metrics as (

    select * from {{ ref('fct_vendor_sales_monthly') }}

),

windowed_insights as (

    select
        *,
        
        -- Net Cashflow
        (total_sales_revenue - abs(coalesce(total_refunded_dollars, 0))) as net_revenue,

        -- Vendor share of category revenue
        safe_divide(
            total_sales_revenue, 
            sum(total_sales_revenue) over (partition by category_name, partition_month)
        ) as category_dominance_index,

        -- Rank within category/month
        rank() over (
            partition by category_name, partition_month 
            order by total_sales_revenue desc
        ) as vendor_rank_in_category,

        -- Category benchmark return rate (derived ONLY for comparison, not redefining fact metric)
        avg(return_rate) over (
            partition by category_name, partition_month
        ) as category_avg_return_rate

    from base_metrics
)

select 
    *,
    
    -- Risk metric
    case 
        when total_sales_revenue = 0 then 0 
        else abs(total_refunded_dollars) / total_sales_revenue 
    end as return_value_ratio,

    -- Anomaly detection
    case 
        when return_rate > (category_avg_return_rate * 1.5) then 'ANOMALY_HIGH_RETURNS'
        when return_rate < (category_avg_return_rate * 0.5) and return_count > 0 then 'LOW_RETURNS'
        else 'NORMAL'
    end as return_anomaly_flag

from windowed_insights
