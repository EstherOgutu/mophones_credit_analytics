# MoPhones Credit Risk Analysis

## Setup & Execution
To replicate this analysis, ensure you have the environment configured and run the following:

<details> <summary><b>Click to expand: DBT Commands</b></summary>

# Run models to build the rpt_credit_analysis tables
dbt run

# Run tests to ensure data integrity
dbt test

</details>

### Analysis & Insights
#### Question 1: How do Arrears and Account Status vary across Customer Segments?

The portfolio demonstrates high demographic sensitivity. Risk is heavily concentrated in the younger demographics (18-25) and lower income brackets (<5,000). A significant finding is the high First Month Default (FMD) rate among these groups, suggesting that current credit vetting may not be capturing affordability accurately for new, younger borrowers.

**Key Performance Table**

**Below is a summary of the most critical risk segments identified:**

Segment Type	Segment Value	Account Status	PAR %	Loan Count
Age	18–25	FMD (First Month Default)	40.96%	3,699
Age	26–35	PAR 30 (1-30 DPD)	29.49%	25,050
Income	Below 5,000	FMD (First Month Default)	46.33%	439
Income	> 150,000	Return	49.73%	4,804

**Strategic Observations:**

**The "Unknown" Data Gap:** Segments with missing demographic data show PAR scores exceeding 100%. This points to a critical need for enforced KYC (Know Your Customer) data collection during onboarding.

**Returns vs. Defaults:** High-income segments show high "Return" rates rather than "FPD." This indicates that risk in top-tier segments is driven by product dissatisfaction or "buyer's remorse" rather than financial distress.

**Volume Risk:** The 26-35 age bracket is the "Engine Room" of the portfolio. While their PAR % isn't the highest, their high loan volume means they represent the largest absolute dollar value at risk.

<details> <summary><b>Click to view Technical SQL & Python Logic</b></summary>

import duckdb
con = duckdb.connect('dev.duckdb')

#### This query joins the credit reporting table with customer demographics 
#### to calculate PAR % and loan distribution.

```python
import duckdb
con = duckdb.connect('dev.duckdb')

# Unified query for Age and Income Risk Analysis
query = """
WITH base AS (
    SELECT 
        'Age' AS segment_type,
        COALESCE(c.age_range, 'Unknown') AS segment_value,
        r.account_status,
        r.ARREARS,
        r.LOAN_PRICE
    FROM rpt_credit_analysis r
    LEFT JOIN income_age_customer_analysis c ON r.loan_id = c.loan_id
    UNION ALL
    SELECT 
        'Income' AS segment_type,
        COALESCE(c.income_range, 'Unknown') AS segment_value,
        r.account_status,
        r.ARREARS,
        r.LOAN_PRICE
    FROM rpt_credit_analysis r
    LEFT JOIN income_age_customer_analysis c ON r.loan_id = c.loan_id
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
results = con.execute(query).df()
print(results)

</details>
