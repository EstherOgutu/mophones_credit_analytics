# MoPhones Credit Risk Analysis

## 🛠 Setup & Execution

To replicate this analysis, ensure you have the environment configured and run the following:

<details>
<summary><b>Click to expand: DBT Commands</b></summary>

```bash
# Run models to build the rpt_credit_analysis tables
dbt run

# Run tests to ensure data integrity
dbt test

Analysis & Insights
Question 1: How do Arrears and Account Status vary across Customer Segments?

Executive Summary: The portfolio shows high risk concentration in younger demographics (18-25) and lower income brackets. Notably, the "Unknown" demographic segment accounts for the highest PAR %, highlighting a critical need for better data collection (KYC) at the point of sale.

Key Data Highlights:

Segment Type	Segment Value	Status	PAR %	Loans
Age	18–25	FMD (First Month Default)	40.96%	3,699
Age	26–35	PAR 30 (1-30 DPD)	29.49%	25,050
Income	Below 5,000	FMD (First Month Default)	46.33%	439
Income	> 150,000	Return	49.73%	4,804
<details> <summary><b>Click to view Python/DuckDB Query for Segment Analysis</b></summary>
