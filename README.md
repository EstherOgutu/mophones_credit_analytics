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

**Age Segment Analysis**

| Segment Type | Age Group | Account Status | Total Loans | PAR % |
| :--- | :--- | :--- | :--- | :--- |
| Age | Unknown | Return | 8,967 | 111.43% |
| Age | Unknown | FPD | 6,483 | 103.44% |
| Age | Unknown | FMD | 4,998 | 90.81% |
| Age | Unknown | PAR 30 | 21,866 | 88.97% |
| Age | 36–45 | Return | 3,162 | 48.95% |
| Age | 26–35 | Return | 7,971 | 46.90% |
| Age | 18–25 | Return | 4,331 | 44.82% |
| Age | 18–25 | FMD | 3,696 | 40.99% |
| Age | 18–25 | FPD | 2,427 | 40.42% |
| Age | 36–45 | FPD | 1,402 | 40.22% |
| Age | Above 55 | Active | 3,905 | 0.13% |

**Income Segment Analysis**

| Segment Type | Income Range | Account Status | Total Loans | PAR % |
| :--- | :--- | :--- | :--- | :--- |
| Income | 150,000 and above | Return | 4,801 | 49.73% |
| Income | 20,000–29,999 | Return | 1,839 | 49.44% |
| Income | 30,000–49,999 | Return | 2,815 | 49.26% |
| Income | Below 5,000 | FMD | 442 | 46.30% |
| Income | 5,000–9,999 | FMD | 450 | 43.71% |
| Income | Below 5,000 | FPD | 93 | 43.40% |
| Income | 10,000–19,999 | FPD | 2,150 | 43.37% |
| Income | 50,000–99,999 | FPD | 3,416 | 40.99% |
| Income | Below 5,000 | PAR 30 | 368 | 30.78% |
| Income | 150,000 and above | Active | 46,816 | 0.22% |
| Income | Below 5,000 | Active | 1,390 | 1.10% |
| Income | Below 5,000 | Paid Off | 167 | 0.00% |

**Risk Driver Analysis**

Based on the demographic and income segmentation, the portfolio is being impacted by four distinct drivers:

**1. The Youth Gap (Age 18–25): 40.96% PAR**

High First Month Defaults (FMD) suggest these are "thin-file" borrowers. The current scoring model likely overestimates the repayment capacity of users with no established credit history.

**2. The Affordability Ceiling (Income <5,000): 46.33% FMD**

Installments likely exceed disposable income. This segment lacks a "financial buffer," making them highly sensitive to even minor economic shocks.

**3. KYC Process Failure (Segment: "Unknown"): >100% Arrears Burden**

Missing demographic data strongly correlates with bypassed sales protocols or identity fraud. It is nearly impossible to collect from a customer who hasn't been properly identified at onboarding.

**4. Premium "Buyer's Remorse" (Income >150,000): 49.73% Return Rate**

This is a Logistics/Product risk, not a credit risk. High-earners are returning devices due to dissatisfaction or high expectations rather than an inability to pay.

**Recommendations**

1. Implement "Step-Up" Credit (Youth 18-25): Start with lower-limit loans to build a repayment track record. Successfully completing a 3-month cycle unlocks higher device tiers.

2. Micro-Payment Alignments (Low-Income): Shift from large monthly installments to daily or weekly micro-payments that align with the cash-flow cycles of informal income earners.

3. Mandatory KYC Gates (Unknowns): Hard-code Point-of-Sale (POS) requirements. The system should block loan disbursement unless all mandatory demographic and identity fields are verified.

4. Enhanced Premium Onboarding (High-Income): Focus on the "unboxing" and setup experience. Providing 24/7 premium support during the first 14 days can reduce the friction that leads to high-value returns.

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


### Question 2: Portfolio Health & Risk Metrics
Portfolio health is best measured by the Arrears Burden % and Cure Rates. The analysis identifies Return and FPD (First Payment Default) as the most critical "terminal" risks, where the company effectively loses nearly 100% of the loan value.
Portfolio health is best measured by the Arrears Burden % and Migration Rates. The most critical "Health" indicators for MoPhones are the FPD (First Payment Default) and Return statuses, as these represent nearly 100% loss of expected revenue.

**Portfolio Performance Breakdown**

I calculated the "Arrears Burden" (Total Arrears / Total Loan Price) to identify which account statuses are the most "toxic" to the company's cash flow.

| Status | Loans | Total Value | Total Arrears | Burden % |
| :--- | :--- | :--- | :--- | :--- |
| Return | 9,410 | 360,677,058 | 363,198,420 | 100.7% |
| FPD | 6,938 | 328,488,667 | 276,977,286 | 84.32% |
| FMD | 5,619 | 238,493,215 | 184,941,861 | 77.55% |
| PAR 30 | 25,584 | 1,007,074,920 | 646,074,797 | 64.15% |
| PAR 7 | 3,782 | 219,711,400 | 13,409,822 | 6.1% |
| Paid Off | 18,941 | 373,978,975 | 21,363,045 | 5.71% |
| Inactive | 4,025 | 243,969,609 | 4,518,051 | 1.85% |
| Active | 53,369 | 3,191,115,285 | 21,766,506 | 0.68% |
| Unknown | 8 | 0 | 0 | 0% |

**Strategic Metrics for Tracking**
1. **Vintage Loss Rates**: Tracking the PAR % of loans based on the month they were issued to identify seasonal risk cohorts.
2. **Cure Rate (Roll-Back)**: The percentage of loans moving from PAR 30 back to Active. A low cure rate suggests that once a customer is 30 days late, the debt is likely unrecoverable.
3. **FPD Efficiency**: Tracking First Payment Defaults as the primary "Quality at Entry" metric to monitor credit scoring accuracy.

**Key Findings**

1. **Terminal Loss Threshold**: Once a loan hits PAR 30, the Arrears Burden jumps to 64%, escalating rapidly to 84% (FPD). This indicates a "broken" collection link where loans rarely "cure" once they pass the 30-day mark.

2. **The Return Paradox**: The Return status carries a burden of 100.7%. This suggests that the cost of processing returns, combined with the loss of device value, exceeds the original loan price, making returns more expensive than some defaults.

3. **Quality at Entry**: The high volume of FPD and FMD (representing over 12,000 loans) indicates that risk is not being managed during the life of the loan, but is inherent from the moment of onboarding.

**Recommendations**

1. **Prioritize FPD Efficiency**: Establish First Payment Default as the primary KPI for the sales team. Incentives should be tied to "Second Payment Success" rather than just the initial device disbursement.

2. **Aggressive PAR 7 Intervention**: Since the burden at PAR 7 is only 6.1%, this is the "Golden Window." Collections efforts should be 5x more aggressive during the first 7 days of arrears to prevent migration to the high-risk PAR 30 bucket.

3. **Cure Rate Optimization**: Implement a "Roll-Back" program for PAR 30 customers, offering one-time installment restructuring to move them back to "Active" status before they reach the terminal FMD/FPD stages.

4. **Refine Vintage Tracking**: Transition from static reporting to Vintage Loss Rates. By tracking PAR % based on the month of disbursement, the business can identify if specific marketing campaigns or seasonal promos are bringing in higher-risk cohorts.

<details> 
<summary><b>Click to view Collection Efficiency Logic (Q2)</b></summary>

```python
import duckdb
con = duckdb.connect('dev.duckdb')

# This query identifies 'toxic' segments by calculating the Arrears Burden %
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

header = f"{'Status':<12} | {'Loans':<8} | {'Total Value':<15} | {'Total Arrears':<15} | {'Burden %'}"
print(header)
print("-" * len(header))

for row in results:
    # Handling None values and formatting with commas but NO dollar sign
    val = row[2] if row[2] is not None else 0
    arrears = row[3] if row[3] is not None else 0
    pct = row[4] if row[4] is not None else 0
    
    # {val:<14,.0f} adds commas for thousands but omits the $
    print(f"{row[0]:<12} | {row[1]:<8} | {val:<14,.0f} | {arrears:<14,.0f} | {pct}%")

con.close()
```

</details>

The following table represents the final output of the rpt_credit_analysis model, correlating demographics, income brackets, and financial risk with customer sentiment (NPS).

age_range │   income_range    │ portfolio_segment │ avg_nps │ customer_count │
│  varchar  │      varchar      │      varchar      │ double  │     int64      │
├───────────┼───────────────────┼───────────────────┼─────────┼────────────────┤
│ 18–25     │ Below 5,000       │ At Risk           │    10.0 │              3 │
│ 18–25     │ Below 5,000       │ High Risk         │    10.0 │              3 │
│ 18–25     │ Below 5,000       │ Healthy           │     9.5 │             37 │
│ 18–25     │ 100,000–149,999   │ Healthy           │     8.1 │            130 │
│ 18–25     │ 20,000–29,999     │ At Risk           │     7.5 │             99 │
│ 18–25     │ 20,000–29,999     │ Healthy           │     7.5 │            436 │
│ 18–25     │ 150,000 and above │ At Risk           │     7.5 │             86 │
│ 18–25     │ 5,000–9,999       │ At Risk           │     7.3 │             11 │
│ 18–25     │ 150,000 and above │ Healthy           │     7.1 │            257 │
│ 18–25     │ 10,000–19,999     │ High Risk         │     7.1 │            152 │
│   ·       │      ·            │     ·             │      ·  │              · │
│   ·       │      ·            │     ·             │      ·  │              · │
│   ·       │      ·            │     ·             │      ·  │              · │
│ Unknown   │ 5,000–9,999       │ High Risk         │     6.0 │             10 │
│ Unknown   │ 30,000–49,999     │ At Risk           │     5.9 │             94 │
│ Unknown   │ 5,000–9,999       │ Healthy           │     5.9 │             91 │
│ Unknown   │ 10,000–19,999     │ At Risk           │     5.6 │             31 │
│ Unknown   │ 50,000–99,999     │ High Risk         │     5.3 │            107 │
│ Unknown   │ 5,000–9,999       │ At Risk           │     5.0 │             19 │
│ Unknown   │ 20,000–29,999     │ At Risk           │     4.5 │             20 │
│ Unknown   │ 10,000–19,999     │ High Risk         │     4.2 │             53 │
│ Unknown   │ 30,000–49,999     │ High Risk         │     4.1 │             75 │
│ Unknown   │ 150,000 and above │ High Risk         │     3.6 │            150 │
├───────────┴───────────────────┴───────────────────┴─────────┴────────────────┤
│ 132 rows (20 shown)                                                5 columns │


By integrating NPS (Net Promoter Score) with credit performance data, we uncovered three critical trends that inform our lending strategy:

1. The "Loyalty of Access" (Low-Income Youth)

Segment: Age 18–25, Income < 5,000.

This segment maintains an NPS of 10.0, even when categorized as High Risk.

- These users highly value credit access. Traditional aggressive collections might destroy this high brand equity. We should implement "Soft Collections" or restructuring plans for this group to maintain long-term loyalty.

2. High-Income Detractors

Segment: Income 150,000+, High Risk.

This group yielded the lowest sentiment in the dataset (3.6 NPS).

- High-earners who fall into arrears are the most dissatisfied. This suggests "Product Friction"—perhaps the repayment interface or the automated reminders are perceived as intrusive by this affluent demographic.

3. The Sentiment-Risk Inverse Correlation

As users move from Healthy to High Risk, we see a 30%–50% drop in NPS across most segments.

Conclusion
Financial stress is a primary driver of brand detraction. Improving the customer experience during financial hardship is the biggest opportunity for increasing overall brand health.