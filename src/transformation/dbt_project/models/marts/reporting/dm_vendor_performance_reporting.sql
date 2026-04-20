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
        (total_sales_revenue - total_refunded_dollars) as net_revenue,

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

        -- Category benchmark return rate
        avg(return_rate) over (
            partition by category_name, partition_month
        ) as category_avg_return_rate,

        -- Percentile-based return rate ranking
        percent_rank() over (
            partition by category_name, partition_month
            order by return_rate
        ) as return_rate_percentile

    from base_metrics
),

final as (

    select 
        *,
        
        -- Risk metric
        case 
            when total_sales_revenue = 0 then 0 
            else total_refunded_dollars / total_sales_revenue 
        end as return_value_ratio,

        -- ANOMALY DETECTION
        case 
            when return_rate_percentile >= 0.95 
                 and total_sales_revenue > 1000 
                 then 'ANOMALY_HIGH_RETURNS'
            when return_rate_percentile <= 0.05 
                 and total_sales_revenue > 1000 
                 and return_count > 0 
                 then 'LOW_RETURNS'
            else 'NORMAL'
        end as return_anomaly_flag

    from windowed_insights
)

select * from final
