/*
    Analysis: Category Mapping Gap Analysis
    Description:
    - Finds raw categories that failed the join to the category_mapping seed.
    - Highlights the volume (occurrences) to help prioritize which categories to map first.
*/

select 
    category_name_standardized as category_fallback_name,
    count(*) as occurrences,
    round(sum(revenue), 2) as unmapped_revenue
from {{ ref('int_iowa_liquor__sales_standardized') }}
where category_mapping_match is null -- Catches the "misses"
group by 1
order by unmapped_revenue desc
