/*
    Model: int_iowa_liquor__sales_standardized
    Layer: Intermediate (Silver)
    Description:
    - Final 'clean-up' of sales data before Gold layer.
    - Standardizes both Vendor and Category dimensions.
    - Implements 3-layer Vendor cleanup (Split -> Map -> Regex Fallback).
*/

{{ config(
    materialized='incremental',
    unique_key=['invoice_id', 'item_id'],
    incremental_strategy='merge',
    partition_by={
      "field": "transaction_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["vendor_name_standardized", "category_group"]
) }}


with base as (
    select
        *,
        {{ normalize_string('vendor_name') }} as vendor_key,
        {{ normalize_string('category_name') }} as category_key
    from {{ ref('int_iowa_liquor__sales_core') }} 

    {% if is_incremental() %}
        where transaction_date >= (
            select date_sub(max(transaction_date), interval 10 day)
            from {{ this }}
        )
    {% endif %}
),

vendor_mapping as (
    select
        *,
        -- Prepare the join key on the mapping side
        {{ normalize_string('raw_vendor_name') }} as mapping_key
    from {{ ref('vendor_mapping') }}
),

category_mapping as (
    select
        {{ normalize_string('raw_category_name') }} as mapping_key,
        canonical_category,
        category_group,
        spirit_type
    from {{ ref('category_mapping') }}
),

standardized as (
    select
        b.*,

        -- Vendor Standardization
        coalesce(
            vm.canonical_vendor_name, 
            b.vendor_name
        ) as vendor_name_standardized,

        -- THE AUDIT COLUMN
        vm.canonical_vendor_name as vendor_mapping_match,

        -- Category Standardization
        coalesce(
            cm.canonical_category, 
            b.category_name 
        ) as category_name_standardized,

        -- THE AUDIT COLUMN
        cm.canonical_category as category_mapping_match,
        
        -- Mapping metadata (with default fallbacks)
        coalesce(cm.category_group, 'OTHER') as category_group,
        coalesce(cm.spirit_type, 'OTHER') as spirit_type

    from base b

    -- Vendor Mapping
    left join vendor_mapping vm 
        on b.vendor_key = vm.mapping_key
    -- Category Mapping    
    left join category_mapping cm
        on b.category_key = cm.mapping_key
)

select * from standardized
