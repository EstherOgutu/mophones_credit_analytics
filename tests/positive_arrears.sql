-- If this query returns any rows, the test fails.
select
    loan_id,
    arrears
from {{ ref('stg_credit_history') }}
where arrears < 0