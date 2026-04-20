/*
    Model: int_iowa_liquor__sales_core
    Layer: Intermediate (Silver)
    Description: 
    - Joins the refined geography (with UNKNOWNs) back to the core sales data.
    - Filters out metadata columns and selects only the 'Core' columns needed for BI.
*/

with sales as (
    select * from {{ ref('stg_iowa_liquor__sales') }}
),

geography as (
    select * from {{ ref('int_iowa_liquor__geography_refined') }}
),

final as (
    select
        -- Identifiers
        s.invoice_id,
        
        -- Normalize transaction_date to DATE for downstream stability
        date(s.transaction_date) as transaction_date,
        
        s.store_id,
        s.store_name,
        
        -- Classify sales
        {{ classify_transaction('s.sale_dollars') }} as transaction_type,
        {{ is_return('s.sale_dollars') }} as is_return,

        -- Geography
        g.city,
        g.county,
        
        -- Descriptive Attributes
        s.category_name,
        s.vendor_name,
        
        -- Metrics
        s.state_bottle_cost,
        s.state_bottle_retail,
        s.sale_bottles,
        s.sale_dollars,
        s.sale_liters

    from sales s
    -- Join on invoice_id to get the 'UNKNOWN' versions of city/county
    left join geography g on s.invoice_id = g.invoice_id
)

select * from final
