{% test inactivity_consistency(model) %}

{#
    Test: inactivity_consistency

    Purpose:
    Validates that inactivity_days is never negative, ensuring temporal consistency
    between last_purchase_date and the dataset anchor date.

    Why this matters:
    Negative inactivity implies incorrect date arithmetic, broken dataset anchoring,
    or future-dated transactions—critical issues in time-based behavioral metrics.

    Failure indicates:
    - Incorrect date_diff logic
    - Misaligned dataset_max_date
    - Corrupt or future transaction timestamps
#}

with max_date as (
    select max(last_purchase_date) as max_date
    from {{ model }}
)

select *
from {{ model }}, max_date
where inactivity_days < 0

{% endtest %}
