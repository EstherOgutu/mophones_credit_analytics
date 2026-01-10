# MoPhones Credit Risk Analysis

## Setup & Execution
To replicate this analysis, ensure you have the environment configured and run the following:

<details> <summary><b>Click to expand: DBT Commands</b></summary>

### Run models to build the rpt_credit_analysis tables
dbt run

### Run tests to ensure data integrity
dbt test

</details>

### 🔍 Question 1: How do Arrears and Account Status vary across Customer Segments?

**Executive Summary:**
The portfolio demonstrates high demographic sensitivity. Risk is heavily concentrated in the **younger demographics (18-25)** and **lower income brackets (<5,000)**. 

<details> 
<summary><b>Click to view Technical SQL & Python Logic (Q1)</b></summary>

```python
import duckdb
con = duckdb.connect('dev.duckdb')
query = """
WITH base AS (
    SELECT 
      'Age' AS segment_type,
      COALESCE(customer.age_range, 'Unknown') AS segment_value,
      credit.account_status,
      credit.ARREARS,
      credit.LOAN_PRICE
    FROM rpt_credit_analysis AS credit
    LEFT JOIN income_age_customer_analysis AS customer ON 
      credit.loan_id = customer.loan_id
    UNION ALL
    SELECT 
        'Income' AS segment_type,
        COALESCE(customer.income_range, 'Unknown') AS segment_value,
        credit.account_status,
        credit.ARREARS,
        credit.LOAN_PRICE
    FROM rpt_credit_analysis AS credit
    LEFT JOIN income_age_customer_analysis AS customer ON 
      credit.loan_id = customer.loan_id
)
SELECT 
    segment_type, 
    segment_value, 
    account_status, 
    COUNT(*) AS loans,
    ROUND(SUM(ARREARS) * 100.0 / NULLIF(SUM(LOAN_PRICE), 0), 2) AS par_pct
FROM base
GROUP BY 1, 2, 3
ORDER BY segment_type, par_pct DESC
"""
results = con.execute(query).fetchall()
for row in results:
    print(row)
con.close()

</details>

