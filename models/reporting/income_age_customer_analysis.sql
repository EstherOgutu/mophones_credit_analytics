WITH base AS (
    SELECT 
      * 
    FROM {{ ref('stg_customers') }}
),

credit_history AS (
    SELECT 
        loan_id,
        snapshot_month,
        arrears -- keeping this for later analysis
    FROM {{ ref('stg_credit_history') }}
),

calculations AS (
    SELECT
      base.*,
      credit.snapshot_month,
      -- Age based on the 2025 reporting date
      DATE_DIFF('year', 
        COALESCE(
        TRY_CAST(dob AS DATE), 
        TRY_STRPTIME(dob, '%m/%d/%y %H:%M')
        ), 
        CAST('2025-12-31' AS DATE)
     ) AS age,
      -- Sum income components and divide by Duration for average monthly income
      (COALESCE(amount_received, 0) + 
        COALESCE(banks_received, 0) + 
        COALESCE(paybills_received, 0)) / NULLIF(loan_duration, 0)                AS avg_monthly_income
    FROM base
    INNER JOIN credit_history AS credit ON 
      base.loan_id = credit.loan_id
),

final_grouping AS (
  SELECT
    *,
    CASE 
      WHEN 
        age BETWEEN 18 AND 25 
      THEN '18–25'
      WHEN 
        age BETWEEN 26 AND 35 
      THEN '26–35'
      WHEN 
        age BETWEEN 36 AND 45 
      THEN '36–45'
      WHEN 
        age BETWEEN 46 AND 55 
      THEN '46–55'
      WHEN 
        age > 55 THEN 'Above 55'
      ELSE 'Unknown'
    END                                           AS age_range,
    CASE 
      WHEN 
        avg_monthly_income < 5000 
      THEN 'Below 5,000'
      WHEN 
        avg_monthly_income BETWEEN 5000 AND 9999 
      THEN '5,000–9,999'
      WHEN 
        avg_monthly_income BETWEEN 10000 AND 19999
      THEN '10,000–19,999'
      WHEN 
        avg_monthly_income BETWEEN 20000 AND 29999 
      THEN '20,000–29,999'
      WHEN 
        avg_monthly_income BETWEEN 30000 AND 49999 
      THEN '30,000–49,999'
      WHEN 
        avg_monthly_income BETWEEN 50000 AND 99999 
      THEN '50,000–99,999'
      WHEN 
        avg_monthly_income BETWEEN 100000 AND 149999 
      THEN '100,000–149,999'
      WHEN 
        avg_monthly_income >= 150000 
      THEN '150,000 and above'
      ELSE 'Unknown'
    END                                           AS income_range
FROM calculations
),

-- This part finds duplicates of (loan_id + snapshot_month) and picks only the first one
deduplicated AS (
    SELECT 
      *,
      ROW_NUMBER() OVER (
          PARTITION BY loan_id, snapshot_month 
          ORDER BY loan_id -- Ensures a stable result
      ) as row_num
    FROM final_grouping
)

SELECT
    * EXCLUDE (row_num) 
FROM deduplicated
WHERE 
  row_num = 1