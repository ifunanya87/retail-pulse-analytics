{% macro classify_transaction(column_name) %}
    case 
        when {{ column_name }} <= 0 then 'RETURN'
        else 'SALE'
    end
{% endmacro %}

{% macro is_return(column_name) %}
    case 
        when {{ column_name }} <= 0 then true
        else false
    end
{% endmacro %}
