{% macro normalize_string(column_name) %}
    upper(trim(regexp_replace({{ column_name }}, r'\s+', ' ')))
{% endmacro %}