/*
    Model: int_iowa_liquor__sales_standardized
    Layer: Intermediate (Silver)
    Description:
    - Final 'clean-up' of sales data before Gold layer.
    - Standardizes both Vendor and Category dimensions.
    - Implements 3-layer Vendor cleanup (Split -> Map -> Regex Fallback).
*/

{{ config(
    materialized='table',
    partition_by={
      "field": "transaction_date",
      "data_type": "date",
      "granularity": "month"
    },
    cluster_by=["vendor_name_standardized", "category_group"]
) }}


with base as (
    select
        *,
        -- Replace any delimiter (/ or ;) with a single pipe |
        -- Split by that pipe
        -- Take the first part [safe_offset(0)]
        split(
            regexp_replace(upper(trim(vendor_name)), r'[/;]', '|'), 
            '|'
        )[safe_offset(0)] as vendor_name_clean
    from {{ ref('int_iowa_liquor__sales_core') }} 
),

vendor_mapping as (
    select * from {{ ref('vendor_mapping') }}
),

category_mapping as (
    select * from {{ ref('category_mapping') }}
),

standardized as (
    select
        b.*,

        -- Vendor Standardization
        coalesce(
            vm.canonical_vendor_name,
            {{ cleanup_vendor_name('b.vendor_name_clean') }}
        ) as vendor_name_standardized,

        -- Category Standardization
        b.category_name as category_name_raw,
        coalesce(cm.canonical_category, 'OTHER') as category_name_standardized,
        coalesce(cm.category_group, 'OTHER') as category_group,
        coalesce(cm.spirit_type, 'OTHER') as spirit_type

    from base b

    -- Vendor Mapping
    left join vendor_mapping vm
        on b.vendor_name_clean = upper(trim(vm.raw_vendor_name))
        
    -- Category Mapping
    left join category_mapping cm
        on upper(trim(b.category_name)) = upper(trim(cm.raw_category_name))
)

select * from standardized
