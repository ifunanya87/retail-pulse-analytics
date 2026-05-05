{% test revenue_reconciliation(
    model,
    fact_model,
    fact_time_column,
    model_time_column,
    grain_columns,
    metric="revenue",
    threshold=0.01
) %}

{#
    Test: revenue_reconciliation

    Purpose:
    Validates that aggregated revenue in the model matches the source fact table
    at the specified grain.

    Why this matters:
    Ensures aggregation correctness and prevents silent data discrepancies
    between fact and mart layers, which can severely impact reporting accuracy.

    Failure indicates:
    - MISSING_IN_GOLD: records present in fact but missing in model
    - MISSING_IN_FACT: records present in model but not in fact (duplication risk)
    - VALUE_MISMATCH: aggregation inconsistencies beyond threshold

    Notes:
    Threshold allows tolerance for minor floating-point differences.
#}

with gold as (
    select
        {{ model_time_column }} as period,

        {% for col in grain_columns %}
        {{ col }},
        {% endfor %}

        sum(total_{{ metric }}) as gold_value
    from {{ model }}
    group by
        {{ model_time_column }},
        {% for col in grain_columns %}
        {{ col }}{% if not loop.last %}, {% endif %}
        {% endfor %}
),

fact as (
    select
        date_trunc({{ fact_time_column }}, month) as period,

        {% for col in grain_columns %}
        {{ col }},
        {% endfor %}

        sum({{ metric }}) as fact_value
    from {{ fact_model }}
    group by
        date_trunc({{ fact_time_column }}, month),
        {% for col in grain_columns %}
        {{ col }}{% if not loop.last %}, {% endif %}
        {% endfor %}
)

select *
from (
    select
        coalesce(g.period, f.period) as period,

        {% for col in grain_columns %}
        coalesce(g.{{ col }}, f.{{ col }}) as {{ col }},
        {% endfor %}

        abs(coalesce(g.gold_value,0) - coalesce(f.fact_value,0)) as diff,

        case
            when g.period is null then 'MISSING_IN_GOLD'
            when f.period is null then 'MISSING_IN_FACT'
            when abs(coalesce(g.gold_value,0) - coalesce(f.fact_value,0)) > {{ threshold }}
                then 'VALUE_MISMATCH'
        end as test_type

    from gold g
    -- inner join to exclude any synthetic rows from date spine
    join fact f
        on g.period = f.period
        {% for col in grain_columns %}
        and g.{{ col }} = f.{{ col }}
        {% endfor %}
)
where test_type is not null

{% endtest %}
