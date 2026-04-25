/*
    Analysis: High-Impact Unmapped Vendors (with Market Share)
    Description: 
    - Identifies gaps in the vendor_mapping seed.
    - Calculates % of "Unmapped Revenue" to prioritize mapping updates.
*/

select 
    vendor_name_standardized as vendor_fallback_name,
    count(*) as transaction_count,
    round(sum(revenue), 2) as unmapped_revenue,
    
    -- Percentage of the total unmapped revenue pool
    round(
        safe_divide(
            sum(revenue), 
            sum(sum(revenue)) over()
        ) * 100, 
        2
    ) as pct_of_unmapped_pool,

    -- Evidence for debugging the mapping
    max(vendor_name) as sample_raw_name 
from {{ ref('int_iowa_liquor__sales_standardized') }}
where vendor_mapping_match is null
group by 1
order by unmapped_revenue desc
limit 20
