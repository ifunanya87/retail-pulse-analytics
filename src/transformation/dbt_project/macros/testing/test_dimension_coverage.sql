{% test dimension_coverage(model, dimension_model, key_column) %}

{#
    Test: dimension_coverage

    Purpose:
    Ensures that all current dimension entities (e.g., stores) exist in the
    aggregated model.

    Why this matters:
    Missing dimension entities indicate join issues, filtering errors, or
    incomplete aggregation logic—leading to silent data loss in reporting.

    Failure indicates:
    - Left join behaving like inner join
    - Missing records in aggregation layer
    - Dimension-model misalignment (SCD2 issues)
#}

with dim as (
    select distinct {{ key_column }} as id
    from {{ dimension_model }}
    where is_current = true
),

fact as (
    select distinct {{ key_column }} as id
    from {{ model }}
)

select *
from dim d
left join fact f
on d.id = f.id
where f.id is null

{% endtest %}
