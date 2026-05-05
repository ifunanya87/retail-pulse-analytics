/*
Model: dim_date
Layer: Silver (Dimensions)

Purpose:
Central calendar table used across all marts to standardize time-based analysis.
Replaces dynamic date spine generation and ensures consistency across models.

Grain:
One row per calendar date
*/

{{ config(
    materialized='table'
) }}

with date_spine as (

    select
        date_day
    from unnest(
        generate_date_array(
            '2020-01-01',   -- start (safe buffer before data)
            '2030-12-31',   -- end (future-proof)
            interval 1 day
        )
    ) as date_day

),

final as (

    select
        -- Primary key
        date_day,

        -- Core
        extract(year from date_day) as year,
        extract(month from date_day) as month,
        extract(day from date_day) as day,
        extract(quarter from date_day) as quarter,

        -- Derived
        format_date('%Y-%m', date_day) as year_month,
        date_trunc(date_day, month) as month_start_date,
        last_day(date_day) as month_end_date,
        concat(extract(year from date_day), '-Q', extract(quarter from date_day)) as year_quarter,

        -- Week logic
        extract(dayofweek from date_day) as day_of_week,
        format_date('%A', date_day) as day_name,
        extract(week from date_day) as week_of_year,
        extract(isoweek from date_day) as iso_week,

        case
            when extract(dayofweek from date_day) in (1, 7) then true
            else false
        end as is_weekend,

        -- Boundary flags
        case when date_day = date_trunc(date_day, month) then true else false end as is_month_start,
        case when date_day = last_day(date_day) then true else false end as is_month_end,

        case when date_day = date_trunc(date_day, quarter) then true else false end as is_quarter_start,
        case when date_day = last_day(date_trunc(date_day, quarter), quarter) then true else false end as is_quarter_end,

        case when date_day = date_trunc(date_day, year) then true else false end as is_year_start,
        case when date_day = last_day(date_trunc(date_day, year), year) then true else false end as is_year_end

    from date_spine

)

select * from final
