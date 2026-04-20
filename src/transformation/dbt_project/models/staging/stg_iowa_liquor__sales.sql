/*
    Staging Model: stg_iowa_liquor__sales
    Layer: Silver
    Purpose: Cast strings to proper types and standardize geography using safe_cast for resilience.
*/

with source as (
    select * from {{ source('iowa_liquor_raw', 'iowa_liquor_sales_external_raw') }}
),

renamed_and_cast as (
    select
        invoice_line_no as invoice_id,
        date as transaction_date,
        store as store_id,
        upper(trim(name)) as store_name, 
        upper(trim(city)) as city,
        upper(trim(county)) as county,
        upper(trim(category_name)) as category_name,
        upper(trim(vendor_name)) as vendor_name,
        
        -- Safe casting strings to numbers to prevent run failures on malformed data
        safe_cast(bottle_volume_ml as float64) as bottle_volume_ml,
        safe_cast(state_bottle_cost as float64) as state_bottle_cost,
        safe_cast(state_bottle_retail as float64) as state_bottle_retail,
        safe_cast(sale_bottles as int64) as sale_bottles,
        safe_cast(sale_dollars as float64) as sale_dollars,
        safe_cast(sale_liters as float64) as sale_liters,
        
        -- DLT Metadata
        _dlt_id,
        _dlt_load_id
    from source
)

select * from renamed_and_cast
