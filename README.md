# Insurance Portfolio SQL Analysis

An end-to-end SQL analytics project built on a simulated insurance company database, covering policy performance, claims behavior, customer risk segmentation, agent/branch productivity, and regional revenue trends.

## Project Overview

This project analyzes an `insurance_portfolio` database using Oracle SQL to answer real business questions an insurance company's management team would care about: where revenue is coming from, which segments are riskiest, which agents and branches are performing best, and how customer demographics relate to claims behavior.

The results were also summarized into an executive PowerPoint presentation for a non-technical audience.

## Repository Structure

```
insurance-portfolio-sql-analysis/
├── README.md
├── data/                  # Source CSV files
│   ├── agents.csv
│   ├── claims.csv
│   ├── customers.csv
│   ├── payments.csv
│   └── policies.csv
├── sql/                   # SQL analysis queries
│   └── insurance_portfolio_queries.sql
└── presentation/          # Executive summary deck
    └── insurance_portfolio_analysis.pptx
```

## Data Model

The database consists of 5 related tables:

| Table | Description |
|---|---|
| `customers` | Customer demographic data (age, city, etc.) |
| `policies` | Insurance policies (type, premium, coverage, status, dates) |
| `claims` | Claims filed against policies (amount, reason, status) |
| `agents` | Sales agents (region, branch) |
| `payments` | Payment records (method, amount) |

## Key Business Questions Answered

**Overall performance**
- Total premiums collected vs. total approved claims
- Year-over-year net revenue and loss ratio trend
- Policy status breakdown (active / completed / cancelled)

**Sales performance**
- Top 5 agents by policies sold and total sales
- Top branches and regions by revenue generated

**Customer & risk analysis**
- Customer count and average premium by city
- Average claim amount by customer age group
- Most common causes of claims (`claim_reason`)
- Riskiest policy type by claim-to-policy ratio and loss ratio
- Average coverage amount for active policies
- Most-used policy type and most common claim per age group

**Other**
- Payment method distribution and average payment size

## Tools Used

- **Oracle SQL** (SQL Developer) — core analysis: subqueries, CTEs, window functions (`RANK() OVER`), `CASE` logic, joins, aggregate functions
- **Excel** — supporting dashboards
- **PowerPoint** — executive-level summary of findings

## Sample Query

Calculating the riskiest policy type by loss ratio:

```sql
with policy_stats as (
    select p.policy_type, count(distinct p.policy_id) as policy_count,
           sum(p.premium_amount) as total_policy
    from policies p
    group by p.policy_type
),
claim_stats as (
    select p.policy_type, count(c.claim_id) as claim_count,
           sum(c.claim_amount) as claim_amount
    from policies p
    join claims c on p.policy_id = c.policy_id
    where c.status = 'Approved'
    group by p.policy_type
)
select ps.policy_type, ps.policy_count, ps.total_policy,
       cs.claim_count, cs.claim_amount,
       round(cs.claim_count / ps.policy_count * 100, 2) as claim_per_policy_pct,
       round(cs.claim_amount / ps.total_policy * 100, 2) as loss_ratio_pct
from policy_stats ps
join claim_stats cs on cs.policy_type = ps.policy_type
order by loss_ratio_pct desc;
```

## Note on Data

The data used in this project is synthetic and was created for learning and portfolio purposes only. It does not represent any real company, customer, or insurance product.

## Author

**Aslan Rustamov**
[LinkedIn](https://www.linkedin.com/in/rustamovaslan/) · [GitHub](https://github.com/Aslan934)
