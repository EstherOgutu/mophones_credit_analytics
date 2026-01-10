-- Combining all the monthly credit files into one list
SELECT 
  "LOAN_ID"                         AS loan_id,
  CAST('2025-01-01' AS DATE)        AS snapshot_month, 
  balance,
  arrears,
  account_status_l2                 AS account_status
FROM {{ ref('seed_credit_2025_01') }}

UNION ALL

SELECT 
  "LOAN_ID"                         AS loan_id,
  CAST('2025-03-31' AS DATE)        AS snapshot_month, 
  balance,
  arrears,
  account_status_l2                 AS account_status
FROM {{ ref('seed_credit_2025_03') }}

UNION ALL

SELECT 
  "LOAN_ID"                         AS loan_id,
  CAST('2025-06-30' AS DATE)        AS snapshot_month, 
  balance,
  arrears,
  account_status_l2                 AS account_status
FROM {{ ref('seed_credit_2025_06') }}

UNION ALL

SELECT 
  "LOAN_ID"                         AS loan_id,
  CAST('2025-09-30' AS DATE)        AS snapshot_month, 
  balance,
  arrears,
  account_status_l2                 AS account_status
FROM {{ ref('seed_credit_2025_09') }}

UNION ALL

SELECT 
  "LOAN_ID"                         AS loan_id,
  CAST('2025-12-30' AS DATE)        AS snapshot_month, 
  balance,
  arrears,
  account_status_l2                 AS account_status
FROM {{ ref('seed_credit_2025_12') }}
WHERE 
  "LOAN_ID" IS NOT NULL