# MoPhones Credit Risk Analysis

## Setup & Execution
To replicate this analysis, ensure you have the environment configured and run the following:

<details> <summary><b>Click to expand: DBT Commands</b></summary>

### Run models to build the rpt_credit_analysis tables
dbt run

### Run tests to ensure data integrity
dbt test

</details>

### Question 1: How do Arrears and Account Status vary across Customer Segments?

The data reveals four distinct risk drivers that require different management strategies:

**The Youth Gap (Age 18–25):**: 40.96% PAR with high First Month Defaults (FMD).
- Likely "thin-file" borrowers with no credit history. High FMD suggests the scoring model is over-estimating the repayment capacity of first-time borrowers.

**The Affordability Ceiling (Income <5,000)**: 46.33% FMD rate.
- Installments likely exceed disposable income. These borrowers lack a "financial buffer," making them highly sensitive to minor economic shocks.

**KYC Process Failure (Segment: "Unknown")**: PAR scores exceeding 100%.
- Missing data usually correlates with bypassed sales protocols or fraud. You cannot collect from a customer you haven't identified.

**The Premium "Buyer's Remorse" (Income >150,000)**: High Return rates (49.73%) rather than defaults.
- This is a Product/Logistics risk, not a credit risk. High-earners are returning devices due to dissatisfaction rather than an inability to pay.

#### Recommendations

1. For Youth (18-25): Introduce "Step-Up" credit. Start with smaller loans to build a "repayment track record" before unlocking higher limits.

2. For Low-Income: Align repayment cycles with income streams (e.g., daily micro-payments instead of large monthly chunks).

3. For "Unknowns": Tighten Point-of-Sale (POS) controls. Make demographic fields mandatory to prevent "ghost" accounts.

4. For Premium Returns: Improve the "Product fit" or trial period experience to reduce the logistical cost of device returns. 

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
```

</details>
