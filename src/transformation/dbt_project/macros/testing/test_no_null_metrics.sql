{% test no_null_metrics(model, columns) %}

{#
    Test: no_null_metrics

    Purpose:
    Ensures that critical metric columns do not contain NULL values.

    Why this matters:
    NULL metrics can break BI dashboards, distort aggregations, and indicate
    missing data or improper default handling (e.g., missing zero-fill logic).

    Failure indicates:
    - Incomplete aggregation
    - Missing joins
    - Failure to apply default values (e.g., 0 instead of NULL)
#}

select *
from {{ model }}
where
{% for col in columns %}
    {{ col }} is null
    {% if not loop.last %} or {% endif %}
{% endfor %}

{% endtest %}
