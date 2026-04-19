/*
    Model: int_iowa_liquor__geography_refined
    Layer: Intermediate (Silver)
    Source: stg_iowa_liquor__sales
    
    Description: 
    - Standardizes geography columns by handling nulls in City and County fields.
    - Implements a 'COALESCE' strategy to replace missing values with 'UNKNOWN' for consistent grouping in downstream analytics.
    - Serves as the primary source for geography-based Marts (Gold layer).
*/


with staging as (
    select * from {{ ref('stg_iowa_liquor__sales') }}
),

refined as (
    select
        * except(city, county), -- Keep everything else
        coalesce(city, 'UNKNOWN') as city,
        coalesce(county, 'UNKNOWN') as county
    from staging
)

select * from refined
