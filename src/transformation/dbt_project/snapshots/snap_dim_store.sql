/*
Snapshot Model: snap_dim_store
Layer: Snapshot (SCD Type 2)
Purpose:
    - Tracks historical changes in store attributes over time
    - Enables point-in-time analysis for store performance, churn, and cohort tracking

Design:
    - Uses dbt snapshot with CHECK strategy
    - Detects changes in store_name, city, and county
    - Relies on clean Silver layer (stg_store_clean)
*/

{% snapshot snap_dim_store %}

{{
    config(
        target_schema='liquor_snapshots',
        unique_key='store_id',
        strategy='check',
        check_cols=['store_name', 'city', 'county']
    )
}}

select
    store_id,
    store_name,
    city,
    county
from {{ ref('stg_store_clean') }}

{% endsnapshot %}
