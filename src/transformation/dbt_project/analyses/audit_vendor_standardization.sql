/*
    Analysis: Vendor Standardization Audit
    Description:
    - This query validates the effectiveness of the 'int_iowa_liquor__sales_standardized' model.
    - Aggregates sales and frequency by the standardized vendor name to identify 
      high-revenue entities that may still require manual mapping.
    - Purpose: Use this to spot "Leaked Variations" (e.g., 'DIAGEO NORTH AMERICA' vs 
      'DIAGEO AMERICAS') that should be added to the 'vendor_mapping.csv' seed.
    - Usage: Run this during the 'Growth' phase of the Medallion architecture setup.
*/

select 
    vendor_name_standardized,
    count(*) as freq,
    round(sum(sale_dollars), 2) as revenue
from {{ ref('int_iowa_liquor__sales_standardized') }}
group by 1
order by revenue desc
