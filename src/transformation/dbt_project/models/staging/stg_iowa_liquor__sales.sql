/*
    Staging Model: stg_iowa_liquor__sales
    Layer: Silver
    Purpose: Cast strings to proper types and standardize geography using safe_cast for resilience.
*/

{{ config(
    materialized='incremental',
    unique_key='invoice_id',
    partition_by={
      "field": "transaction_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["invoice_id", "vendor_name"]
) }}

with source as (
    select * 
    from {{ source('iowa_liquor_raw', 'iowa_liquor_sales_external_raw') }}

    {% if is_incremental() %}
        where _dlt_load_id > (
            select max(_dlt_load_id) from {{ this }}
        )
    {% endif %}
),

renamed_and_cast as (
    select
        -- Identifiers
        invoice_line_no as invoice_id,
        store as store_id,
        vendor_no as vendor_id,
        itemno as item_id,

        -- Explicitly cast to timestamp to match your partition config
        safe_cast(date as date) as transaction_date,
        
        -- Descriptive (Upper + Trim)
        upper(trim(name)) as store_name, 
        upper(trim(city)) as city,
        upper(trim(county)) as county,
        upper(trim(category_name)) as category_name,
        upper(trim(vendor_name)) as vendor_name,
        upper(trim(im_desc)) as item_description,
        
        -- Safe casting strings to numbers
        -- Quantitative (Metrics)
        safe_cast(pack as int64) as pack_size,
        safe_cast(bottle_volume_ml as float64) as bottle_volume_ml,
        safe_cast(state_bottle_cost as float64) as state_bottle_cost,
        safe_cast(state_bottle_retail as float64) as state_bottle_retail,
        safe_cast(sale_bottles as int64) as bottles_sold,
        safe_cast(sale_dollars as float64) as revenue,
        safe_cast(sale_liters as float64) as volume_liters_sold,
        safe_cast(sale_gallons as float64) as volume_gallons_sold,
        
        -- DLT Metadata
        _dlt_id,
        _dlt_load_id
    from source
)

select * from renamed_and_cast
