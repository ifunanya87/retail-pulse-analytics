{% test no_negative_values(model, columns) %}

{#
    Test: no_negative_values

    Purpose:
    Ensures that specified numeric metrics do not contain negative values.

    Why this matters:
    Metrics like revenue, volume, and transaction counts should be non-negative
    in this domain. Negative values typically indicate aggregation errors,
    sign issues, or corrupted upstream data.

    Failure indicates:
    - Incorrect aggregation logic
    - Data ingestion anomalies
    - Unexpected business rule violations
#}

select *
from {{ model }}
where
{% for col in columns %}
    {{ col }} < 0
    {% if not loop.last %} or {% endif %}
{% endfor %}

{% endtest %}
