/*
 Staging Model: stg_store_clean
Layer: Silver
Purpose:
    - takes raw staging sales data
    - extracts store-level attributes
    - removes duplicates
    - keeps only the latest observed version per store
*/

select
    store_id,
    store_name,
    coalesce(city, '{{ var("default_unknown_string") }}') as city,
    coalesce(county, '{{ var("default_unknown_string") }}') as county,
    _dlt_load_id as ingested_at

from {{ ref('stg_iowa_liquor__sales') }}

qualify row_number() over (
    partition by store_id
    order by _dlt_load_id desc
) = 1
