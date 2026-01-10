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

