WITH customers AS (
    SELECT 
      * 
    FROM {{ ref('income_age_customer_analysis') }} AS customers
),

credit_history AS (
    SELECT 
      * 
    FROM {{ ref('stg_credit_history') }} AS credit
),

calculations AS (
    SELECT
      credit.snapshot_month,
      credit.loan_id,
      credit.balance,
      credit.arrears,
      credit.account_status,
      -- Look at the arrears from the PREVIOUS month for this loan
      LAG(credit.arrears) OVER (PARTITION BY credit.loan_id ORDER BY credit.snapshot_month)        AS previous_month_arrears,
      -- Look at the status from the PREVIOUS month
      LAG(credit.account_status) OVER (PARTITION BY credit.loan_id ORDER BY credit.snapshot_month) AS previous_month_status
    FROM credit_history AS credit
)

SELECT
    calculations.*,
    customers.gender,
    customers.loan_price,
    customers.nps_score,
    customers.age_range,
    customers.income_range,
    -- Calculate the change in arrears
    (calculations.arrears - COALESCE(calculations.previous_month_arrears, 0)) AS arrears_change,

    -- Using the Macros
    {{ arrears_ratio('calculations.arrears', 'customers.loan_price') }}       AS risk_pct,
    CASE 
      WHEN 
        {{ arrears_ratio('calculations.arrears', 'customers.loan_price') }} > 10 
      THEN 'High Risk'
      WHEN 
        {{ arrears_ratio('calculations.arrears', 'customers.loan_price') }} > 0 
      THEN 'At Risk'
      ELSE 'Healthy'
    END                                                                       AS portfolio_segment,
    -- Create a flag for "Worsening" accounts
    CASE 
      WHEN 
        calculations.arrears > calculations.previous_month_arrears 
      THEN 'Worsening'
      WHEN 
        calculations.arrears < calculations.previous_month_arrears 
      THEN 'Improving'
      ELSE 'Stable'
    END                                                                       AS trend_direction
FROM calculations 
LEFT JOIN customers ON 
  calculations.loan_id = customers.loan_id