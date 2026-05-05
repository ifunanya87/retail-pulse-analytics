{% test churn_logic(model) %}

{#
    Test: churn_logic

    Purpose:
    Validates that churn_status correctly reflects inactivity_days based on
    defined business rules.

    Why this matters:
    Churn classification drives downstream analytics, segmentation, and
    operational decisions. Misclassification leads to incorrect insights
    and potentially flawed business actions.

    Failure indicates:
    - Incorrect CASE logic implementation
    - Boundary condition errors (e.g., 30/60/90 day thresholds)
    - Drift between business rules and model logic
#}

select *
from {{ model }}
where
    (inactivity_days <= 30 and churn_status != 'ACTIVE')
    or
    (inactivity_days > 30 and inactivity_days <= 60 and churn_status != 'AT_RISK_30_60')
    or
    (inactivity_days > 60 and inactivity_days <= 90 and churn_status != 'AT_RISK_60_90')
    or
    (inactivity_days > 90 and churn_status != 'CHURNED_90_PLUS')

{% endtest %}
