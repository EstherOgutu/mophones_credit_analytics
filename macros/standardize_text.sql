{% macro standardize_column(column_name) %}
    -- Capitalizing first letter, lowercase the rest, and trim spaces
    upper(substring(trim({{ column_name }}), 1, 1)) || 
    lower(substring(trim({{ column_name }}), 2))
{% endmacro %}