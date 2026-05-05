/*
    Model: int_iowa_liquor__geography_refined
    Layer: Intermediate (Silver)
    Source: stg_iowa_liquor__sales
    
    Description: 
    - Standardizes geography columns by handling nulls in City and County fields.
    - Retains only necessary columns (invoice_id, city, county).
    - Incrementally processes new/updated records for efficiency.
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
) }}

with staging as (

    select
        invoice_id,
        city,
        county,
        transaction_date
    from {{ ref('stg_iowa_liquor__sales') }}

    {% if is_incremental() %}
        where transaction_date >= (
            select date_sub(max(transaction_date), interval 10 day)
            from {{ this }}
        )
    {% endif %}

),

refined as (

    select
        invoice_id,
        transaction_date,
        coalesce(city, '{{ var("default_unknown_string") }}') as city,
        coalesce(county, '{{ var("default_unknown_string") }}') as county
    from staging

)

select * from refined
