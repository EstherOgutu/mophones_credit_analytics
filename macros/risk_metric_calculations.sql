{% macro arrears_ratio(arrears_column, total_loan_column) %}
    -- Handles division by zero and rounds to 2 decimal places
    ROUND(
        (COALESCE({{ arrears_column }}, 0) / NULLIF({{ total_loan_column }}, 0)) * 100, 
        2
    )
{% endmacro %}