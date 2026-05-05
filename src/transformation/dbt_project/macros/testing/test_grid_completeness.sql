{% test grid_completeness(
    model,
    fact_model,
    dimension_column,
    model_time_column,
    fact_time_column
) %}

{#
    Test: grid_completeness

    Purpose:
    Validates that the model contains a complete grid of dimension × time
    combinations based on the source fact data.

    Why this matters:
    Missing rows in aggregated marts break time-series continuity and lead to
    incorrect trend analysis, especially when zero-fill logic is expected.

    Failure indicates:
    - Missing synthetic rows (no zero-fill)
    - Incomplete aggregation coverage
    - Broken time spine logic
#}

with dims as (
    select distinct {{ dimension_column }} as dim
    from {{ fact_model }}
),

times as (
    select distinct date_trunc({{ fact_time_column }}, month) as period
    from {{ fact_model }}
),

expected as (
    select d.dim, t.period
    from dims d
    cross join times t
),

actual as (
    select
        {{ dimension_column }} as dim,
        {{ model_time_column }} as period
    from {{ model }}
)

select *
from expected e
left join actual a
on e.dim = a.dim
and e.period = a.period
where a.dim is null

{% endtest %}
