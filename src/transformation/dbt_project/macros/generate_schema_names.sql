{% macro generate_schema_name(custom_schema_name, node) -%}
    {# 
       If a custom schema is provided (like 'liquor_gold'), use ONLY that name.
       Otherwise, use the default target schema (liquor_silver).
    #}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
