SELECT
  income."Loan Id"                         AS loan_id,
  dob.date_of_birth                        AS dob,
  {{ standardize_column('gender') }}       AS gender,
  {{ standardize_column('citizenship') }}  AS citizenship,
  income.duration                          AS loan_duration,
  income.received                          AS amount_received,
  income."Persons Received From Total"     AS total_persons_received,
  income."Banks Received"                  AS banks_received,
  income."Paybills Received Others"        AS paybills_received,
  sales.sale_id,
  sales.sale_date,
  sales.sale_type,
  sales.cash_price,
  sales.loan_price,
  sales.product_name,
  sales.loan_term,
  sales.returned                           AS is_returned
FROM {{ ref('seed_customer_income') }} AS income
LEFT JOIN {{ ref('seed_customer_dob') }} AS dob ON
  income."Loan Id" = dob."Loan Id "
LEFT JOIN {{ ref('seed_customer_gender') }} AS gender ON
  income."Loan Id" = gender."Loan Id"
LEFT JOIN {{ ref('seed_sales_data') }} AS sales ON
  income."Loan Id" = sales."Loan Id"
WHERE 
  income."Loan Id" IS NOT NULL