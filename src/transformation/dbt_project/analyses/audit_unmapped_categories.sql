/*
    Analysis: Unmapped Category Audit
    Layer: Quality Assurance / Maintenance
    Description:
    - Identifies 'raw_category_names' from the source data that do not exist in the 'category_mapping' seed.
    - Resulting rows show as 'OTHER' in the standardized model.
    - Purpose: Use this to maintain 100% mapping coverage. Any result from this query 
      should be copied and added to 'seeds/category_mapping.csv'.
    - Usage: Run this periodically or after a new data refresh from the state of Iowa.
*/

select 
    category_name_raw, 
    category_name_standardized,
    count(*) as occurrences
from {{ ref('int_iowa_liquor__sales_standardized') }}
where category_name_standardized = 'OTHER'
group by 1, 2
order by occurrences desc
