/*
    Model: fct_vendor_sales_monthly
    Layer: Gold (Base Fact)
    Description: 
    - Aggregates atomic sales transactions into a monthly vendor-category grain.
    - Utilizes 'insert_overwrite' strategy to ensure idempotent updates and 
      proper handling of late-arriving data/refunds.
    - Serves as the primary physical source for the Semantic/Reporting layer.
*/

{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            "field": "partition_month",
            "data_type": "date",
            "granularity": "month"
        },
        cluster_by=['vendor_name', 'category_name']
    )
}}

with raw_source as (

    select 
        vendor_name_standardized,
        category_name_standardized,
        transaction_type,
        sale_dollars,
        sale_liters,
        invoice_id,
        
        date_trunc(transaction_date, month) as partition_month,
        
        extract(year from transaction_date) as year,
        extract(month from transaction_date) as month
        
    from {{ ref('int_iowa_liquor__sales_standardized') }}
),

base_events as (

    select *
    from raw_source

    {% if is_incremental() %}
    where partition_month >= (
        select date_sub(
            max(date(partition_month)),
            interval 2 month
        )
        from {{ this }}
    )
{% endif %}
),

final_aggregation as (

    select
        vendor_name_standardized as vendor_name,
        category_name_standardized as category_name,
        partition_month,
        year,
        month,

        sum(case when transaction_type = 'SALE' then sale_dollars else 0 end) as total_sales_revenue,
        sum(case when transaction_type = 'SALE' then sale_liters else 0 end) as total_sales_liters,
        count(case when transaction_type = 'SALE' then invoice_id end) as total_sales_count,

        -- FIX: normalize returns (critical fix)
        sum(case when transaction_type = 'RETURN' then abs(sale_dollars) else 0 end) as total_refunded_dollars,
        count(case when transaction_type = 'RETURN' then invoice_id end) as return_count

    from base_events
    group by 1, 2, 3, 4, 5
)

select
    *,
    safe_divide(
        return_count,
        nullif(total_sales_count, 0)
    ) as return_rate

from final_aggregation
