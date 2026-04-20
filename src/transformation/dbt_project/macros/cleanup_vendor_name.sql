{% macro cleanup_vendor_name(column_name) %}
    upper(trim(
        regexp_replace(
            {{ column_name }},
            r'(?i)\b(LLC|INC|CORPORATION|CORP|LTD|INCORPORATED)\b\.?',
            ''
        )
    ))
{% endmacro %}
