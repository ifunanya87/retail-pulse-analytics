/*
    Model: int_iowa_liquor__sales_core
    Layer: Intermediate (Silver)
    Description: 
    - Joins the refined geography (with UNKNOWNs) back to the core sales data.
    - Filters out metadata columns and selects only the 'Core' columns needed for BI.
*/

{{ config(
    materialized='incremental',
    unique_key='invoice_id',
    incremental_strategy='merge',
    partition_by={
      "field": "transaction_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["vendor_name", "county"]
) }}

with sales as (
    select * from {{ ref('stg_iowa_liquor__sales') }}

    {% if is_incremental() %}
        where transaction_date >= (
            select date_sub(max(transaction_date), interval 10 day)
            from {{ this }}
        )
    {% endif %}
),

geography as (
    select * from {{ ref('int_iowa_liquor__geography_refined') }}
),

final as (
    select
        -- Identifiers
        s.invoice_id,
        s.store_id,
        s.vendor_id,
        s.item_id,
        
        -- Temporal
        s.transaction_date,
        
        -- Geography
        g.city,
        g.county,
        
        -- Descriptive Attributes
        s.store_name,
        s.category_name,
        s.vendor_name,
        s.item_description,
        
        -- Business Logic
        {{ classify_transaction('s.revenue') }} as transaction_type,
        {{ is_return('s.revenue') }} as is_return,

        -- Metrics
        s.pack_size,
        s.bottle_volume_ml,
        s.state_bottle_cost,
        s.state_bottle_retail,
        s.bottles_sold,
        s.revenue,
        s.volume_liters_sold,
        s.volume_gallons_sold

    from sales s
    -- Left join
    left join geography g 
        on s.invoice_id = g.invoice_id 
        and s.transaction_date = g.transaction_date
)

select * from final
