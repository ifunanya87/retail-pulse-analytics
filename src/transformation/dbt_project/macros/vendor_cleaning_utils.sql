/*    
    PURPOSE: 
    This utility provides a standardized, two-stage cleaning process for liquor vendor names.
    Liquor data often contains "noise" from the Socrata API, including multiple vendors 
    per transaction (Joint Ventures) and inconsistent legal suffixes (LLC, INC, etc.).

    MACROS INCLUDED:
    1. cleanup_vendor_name: 
       - Uses Regex to strip legal entity suffixes and standardizes casing/whitespace.
    2. get_normalized_vendor: 
       - Acts as a 'Wrapper' to first handle structural delimiters (/, ;) and then
         calls cleanup_vendor_name for suffix removal.

    USAGE:
    Used primarily in the 'Silver' layer (int_iowa_liquor__sales_standardized) to 
    prepare vendor strings for joining against the vendor_mapping seed file.
*/

{% macro cleanup_vendor_name(column_name) %}
    upper(trim(
        regexp_replace(
            {{ column_name }},
            r'(?i)[,.\s]*\b(LLC|INC|CORPORATION|CORP|LTD|INCORPORATED)\b\.?',
            ''
        )
    ))
{% endmacro %}

{% macro get_normalized_vendor(column_name) %}
    {# Step 1: Structural Clean (Split/Trim) #}
    {% set split_logic %}
        split(regexp_replace(upper(trim({{ column_name }})), r'[/;]', '|'), '|')[safe_offset(0)]
    {% endset %}

    {# Step 2: Suffix Clean (Strip LLC/INC using your existing macro) #}
    {{ cleanup_vendor_name(split_logic) }}
{% endmacro %}
