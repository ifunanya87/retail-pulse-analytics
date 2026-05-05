/*
Dimension Model: dim_store
Layer: Silver (Dimensions)

Purpose:
    - Provides a conformed, historized dimension of retail endpoints within Iowa’s liquor distribution system
    - Enables time-aware analysis of store attributes and structural changes over time (SCD Type 2)
    - Supports downstream analysis of store-level distribution activity, inactivity patterns, and endpoint stability within the supply network

Design:
    - Built from dbt snapshot (snap_dim_store)
    - Uses surrogate key for SCD versioning
    - Supports current and historical store states for time-based analysis
*/

select
    -- Surrogate key for SCD versioning
    {{ dbt_utils.generate_surrogate_key(['store_id', 'dbt_valid_from']) }} as store_sk,

    store_id,
    store_name,
    city,
    county,

    -- SCD Type 2 metadata
    dbt_valid_from as valid_from,
    dbt_valid_to as valid_to,

    case
        when dbt_valid_to is null then true
        else false
    end as is_current

from {{ ref('snap_dim_store') }}
