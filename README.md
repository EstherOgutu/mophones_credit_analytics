# MoPhones Credit Risk Analysis

## Setup & Execution
To replicate this analysis, ensure you have the environment configured and run the following:

<details>
<summary><b>Click to expand: DBT Commands</b></summary>

```bash
# Run models to build the rpt_credit_analysis tables
dbt run

# Run tests to ensure data integrity
dbt test

</details>

Analysis & Insights
Question 1: How do Arrears and Account Status vary across Customer Segments?

Executive Summary: The portfolio shows high risk concentration in younger demographics (18-25) and lower income brackets. Notably, the "Unknown" demographic segment accounts for the highest PAR %, highlighting a critical need for better data collection (KYC) at the point of sale.

Key Data Points:

Youth Risk: The 18-25 age group has a 40.96% First Month Default (FMD) rate.

Volume Hub: The 26-35 segment holds the most loans (~70k) but has a 29.49% PAR 30 rate.

Income Paradox: High-income earners (>150k) have high Return rates (49%), suggesting buyer's remorse rather than a lack of funds.

<details> <summary><b>Click to view Python/DuckDB Query for Segment Analysis</b></summary>

import duckdb
con = duckdb.connect('dev.duckdb')

# This query aggregates Arrears, PAR %, and FPD by Age and Income
query = """
    WITH base AS (
        -- [Your final corrected query goes here]
    )
    SELECT * FROM base;
"""
results = con.execute(query).df()
print(results)

</details>

