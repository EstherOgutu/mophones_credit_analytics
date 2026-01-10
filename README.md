# MoPhones Credit Risk Analysis

## Setup & Execution
To replicate this analysis, ensure you have the environment configured and run the following:

<details> <summary><b>Click to expand: DBT Commands</b></summary>

### Run models to build the rpt_credit_analysis tables
dbt run

### Run tests to ensure data integrity
dbt test

</details>

### Analysis & Insights
#### Question 1: How do Arrears and Account Status vary across Customer Segments?

The portfolio demonstrates high demographic sensitivity. Risk is heavily concentrated in the younger demographics (18-25) and lower income brackets (<5,000). A significant finding is the high First Month Default (FMD) rate among these groups, suggesting that current credit vetting may not be capturing affordability accurately for new, younger borrowers.

**Key Performance Table**

**Below is a summary of the most critical risk segments identified:**

| Segment Type | Segment Value | Account Status | Loans | PAR % |
| :--- | :--- | :--- | :--- | :--- |
| **Income** | Below 5,000 | FMD (First Month Default) | 439 | **46.33%** |
| **Age** | 18–25 | FMD (First Month Default) | 3,699 | **40.96%** |
| **Age** | 26–35 | PAR 30 (1-30 DPD) | 25,050 | **29.49%** |
| **Income** | > 150,000 | Return | 4,804 | **49.73%** |
| **Age** | Unknown | Return | 8,918 | **112.22%** |

**Strategic Observations:**

**The "Unknown" Data Gap:** Segments with missing demographic data show PAR scores exceeding 100%. This points to a critical need for enforced KYC (Know Your Customer) data collection during onboarding.

**Returns vs. Defaults:** High-income segments show high "Return" rates rather than "FPD." This indicates that risk in top-tier segments is driven by product dissatisfaction or "buyer's remorse" rather than financial distress.

**Volume Risk:** The 26-35 age bracket is the "Engine Room" of the portfolio. While their PAR % isn't the highest, their high loan volume means they represent the largest absolute dollar value at risk.

<details>
<summary><b>Click to view Technical SQL & Python Logic</b></summary>

```python
import duckdb
con = duckdb.connect('dev.duckdb')

query = """
WITH base AS (
    SELECT 
      'Age'                                   AS segment_type,
      COALESCE(customer.age_range, 'Unknown') AS segment_value,
      credit.account_status,
      credit.ARREARS,
      credit.LOAN_PRICE
    FROM rpt_credit_analysis AS credit
    LEFT JOIN income_age_customer_analysis AS customer ON 
      credit.loan_id = customer.loan_id

    UNION ALL

    SELECT 
      'Income'                                   AS segment_type,
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
  COUNT(*)                                                    AS loans,
  ROUND(SUM(ARREARS) * 100.0 / NULLIF(SUM(LOAN_PRICE), 0), 2) AS par_pct
FROM base
GROUP BY 
  1, 2, 3
ORDER BY 
  segment_type, 
  par_pct DESC
"""

# Fetch results 
results = con.execute(query).fetchall()

for row in results:
    print(row)

con.close()

</details>

Question 2: Which outcomes best indicate portfolio health, and what metrics should be used?

Executive Summary: Portfolio health is best measured by the Arrears Burden % and Migration Rates. The most critical "Health" indicators for MoPhones are the FPD (First Payment Default) and Return statuses, as these represent nearly 100% loss of expected revenue.

📊 Portfolio Performance Breakdown

I calculated the "Arrears Burden" (Total Arrears / Total Loan Price) to identify which account statuses are the most "toxic" to the company's cash flow.

Status	Total Loans	Total Arrears	Arrears Burden %
Return	9,410	$363,198,420	100.70%
FPD (First Payment Default)	6,938	$276,977,286	84.32%
FMD (First Month Default)	5,619	$184,941,861	77.55%
PAR 30	25,584	$646,074,797	64.15%
PAR 7	3,782	$13,409,822	6.10%
Active	53,369	$21,766,506	0.68%
🔍 Strategic Metrics for Tracking

Vintage Loss Rates: Tracking the PAR % of loans based on the month they were issued to identify seasonal risk cohorts.

Cure Rate (Roll-Back): The percentage of loans moving from PAR 30 back to Active. A low cure rate suggests that once a customer is 30 days late, the debt is likely unrecoverable.

FPD Efficiency: Tracking First Payment Defaults as the primary "Quality at Entry" metric to monitor credit scoring accuracy.

<details> <summary><b>💻 Click to view Collection Efficiency Logic (Q2)</b></summary>

Python
import duckdb
con = duckdb.connect('dev.duckdb')

query = """
    SELECT 
        account_status,
        COUNT(*) AS total_loans,
        ROUND(SUM(LOAN_PRICE), 0) AS total_value,
        ROUND(SUM(ARREARS), 0) AS total_arrears,
        ROUND((SUM(ARREARS) / NULLIF(SUM(LOAN_PRICE), 0)) * 100, 2) AS arrears_burden_pct
    FROM rpt_credit_analysis
    GROUP BY 1
    ORDER BY arrears_burden_pct DESC
"""
results = con.execute(query).fetchall()
for row in results:
    print(row)
</details>
