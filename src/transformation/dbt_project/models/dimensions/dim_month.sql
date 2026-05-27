/*
Model: dim_month
Layer: Silver (Dimensions)

Purpose:
Central month-grain dimension table used to resolve many-to-many relationship 
mismatches between base facts and monthly aggregated performance marts. 
Collapses daily date logic into a unique primary key for clean star-schema filtering.

Grain:
One row per unique calendar month (snapped to month_start_date)
*/

{{ config(materialized='table') }}

with unique_months as (
    select distinct
        month_start_date
    from {{ ref('dim_date') }}
)

select
    month_start_date,
    extract(year from month_start_date) as year,
    extract(month from month_start_date) as month_number,
    
    -- Formats year and month into a clean tracking string
    format_date('%Y-%m', month_start_date) as year_month_string

from unique_months
order by month_start_date asc
