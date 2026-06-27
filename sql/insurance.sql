select * from agents;
select * from claims;
select * from customers;
select * from payments;
select * from policies;

-- A. General indicators
--1.	Calculate the total insurance premium and total paid claim amount.
SELECT 
    (SELECT SUM(premium_amount) FROM policies) AS total_premiums,
    (SELECT SUM(claim_amount)   FROM claims WHERE status = 'Approved')   AS total_claims
FROM DUAL;

--2.	Find the yearly net revenue (premium - claims) trend.

SELECT 
    EXTRACT(YEAR FROM p.start_date)                                       AS policy_year,
    SUM(p.premium_amount)                                                 AS total_premium,
    NVL(SUM(c.claim_amount), 0)                                           AS total_claim,
    SUM(p.premium_amount) - NVL(SUM(c.claim_amount), 0)                   AS net_revenue,
    ROUND(NVL(SUM(c.claim_amount), 0) / SUM(p.premium_amount) * 100, 2)  AS loss_ratio_pct
FROM policies p
LEFT JOIN (
    SELECT policy_id, SUM(claim_amount) AS claim_amount
    FROM claims
    WHERE status = 'Approved'
    GROUP BY policy_id
) c ON c.policy_id = p.policy_id
GROUP BY EXTRACT(YEAR FROM p.start_date)
ORDER BY policy_year;


--3.	Get the count of active, completed, and cancelled policies.
select status, count(*) as count_policies from policies
group by status;


--4.	Find the top 5 agents with the most policies sold.

select a.agent_id,a.agent_name, a.region,a.branch,
count(p.policy_id) as policy_count, 
sum(p.premium_amount) as total_sales
from agents a
join policies p on a.agent_id = p.agent_id
group by a.agent_id,a.agent_name, a.region,a.branch
order by policy_count desc
fetch first 5 rows only;

--5.	Which 3 branches generate the most revenue?

select a.branch as branch, sum(p.premium_amount) || ' AZN' as premium
from agents a
join policies p on a.agent_id=p.agent_id
group by a.branch
order by sum(p.premium_amount) desc
fetch first 3 rows only;

--B. Customer and risk analysis
    --6.	Customer count and average premium by city.
select c.city, count(distinct customer_id) as customer_count, round(avg(p.premium_amount),2) as avg_premium
from customers c
join policies p using(customer_id)
group by c.city;


--7.	Average claim amount by customer age group.

WITH customer_claims AS (
    SELECT 
        cu.customer_id,
        c.claim_amount,
        CASE 
            WHEN cu.age BETWEEN 18 AND 25 THEN '18-25'
            WHEN cu.age BETWEEN 26 AND 35 THEN '26-35'
            WHEN cu.age BETWEEN 36 AND 45 THEN '36-45'
            WHEN cu.age BETWEEN 46 AND 55 THEN '46-55'
            WHEN cu.age BETWEEN 56 AND 65 THEN '56-65'
            ELSE '65+'
        END AS age_group
    FROM customers cu
    JOIN policies p   ON p.customer_id = cu.customer_id
    LEFT JOIN claims c ON c.policy_id = p.policy_id  -- LEFT JOIN
    WHERE c.status = 'Approved' OR c.status IS NULL   -- keep no-claim customers
)
SELECT 
    age_group,
    COUNT(DISTINCT customer_id)    AS customer_count,
    ROUND(AVG(claim_amount))       AS avg_claim_amount
FROM customer_claims
GROUP BY age_group
ORDER BY age_group;

--8.	Event types causing the most claims (claim_reason).

select claim_reason, count(*) as claim_count
from claims
where status='Approved'
group by claim_reason
order by claim_count desc;

--9.	Which insurance type is the riskiest (based on claim/policy ratio)?

with policy_stats as (
select
p.policy_type, count(distinct p.policy_id) as policy_count,
sum(p.premium_amount) as total_policy
from policies p
group by p.policy_type),

claim_stats as (
select p.policy_type, count(c.claim_id) as claim_count,
sum(c.claim_amount) as claim_amount
from policies p
join claims c on p.policy_id = c.policy_id
where c.status='Approved'
group by p.policy_type)

select
ps.policy_type,
ps.policy_count,
ps.total_policy,
cs.claim_count,
cs.claim_amount,
round(cs.claim_count/ps.policy_count*100,2) as claim_per_policy_pct,
round(cs.claim_amount/ps.total_policy*100,2) as loss_ratio_pct
from policy_stats ps
join claim_stats cs on cs.policy_type=ps.policy_type
order by loss_ratio_pct desc;

--10.	What is the average coverage amount of active policies?

select policy_type, round(avg(coverage_amount),2) || ' USD' as avg_coverage
from policies
where status = 'Active'
group by policy_type;


--11.	Top 5 branches by insurance sales.
select a.branch, 
sum(p.premium_amount) as total_sales
from agents a
join policies p on a.agent_id = p.agent_id
group by a.branch
order by sum(p.premium_amount) desc
fetch first 5 rows only;


 --11.	Analysis of regions by insurance sales.
SELECT 
    a.region,
    COUNT(DISTINCT p.policy_id)                                      AS count_policies,
    COUNT(DISTINCT cu.customer_id)                                   AS customer_count,
    SUM(p.premium_amount)                                            AS total_premium,
    NVL(SUM(c.claim_amount), 0)                                      AS total_claims,
    SUM(p.premium_amount) - NVL(SUM(c.claim_amount), 0)              AS net_revenue
FROM agents a
JOIN policies p    ON p.agent_id = a.agent_id
JOIN customers cu  ON cu.customer_id = p.customer_id
LEFT JOIN (
    SELECT policy_id, SUM(claim_amount) AS claim_amount
    FROM claims
    WHERE status = 'Approved'        
    GROUP BY policy_id
) c ON c.policy_id = p.policy_id
GROUP BY a.region
ORDER BY total_premium DESC
FETCH FIRST 5 ROWS ONLY;

--Customer registration count distribution by city
select city, count(*) as customer_count
from customers
group by city;

--Risk Analysis by Insurance Type

SELECT 
    p.policy_type,
    COUNT(DISTINCT p.policy_id)                                    AS total_policies,
    COUNT(DISTINCT c.claim_id)                                     AS total_claims,
    ROUND(COUNT(DISTINCT c.claim_id) / 
          COUNT(DISTINCT p.policy_id) * 100, 2)                    AS claim_per_policy_pct,
    SUM(p.premium_amount)                                          AS total_premium,
    NVL(SUM(c.total_claim), 0)                                     AS total_claims_amount,
    ROUND(NVL(SUM(c.total_claim), 0) / 
          SUM(p.premium_amount) * 100, 2)                          AS loss_ratio_pct,
    CASE
        WHEN ROUND(NVL(SUM(c.total_claim), 0) / 
             SUM(p.premium_amount) * 100, 2) > 120 THEN 'Critical'
        WHEN ROUND(NVL(SUM(c.total_claim), 0) / 
             SUM(p.premium_amount) * 100, 2) > 80  THEN 'High'
        WHEN ROUND(NVL(SUM(c.total_claim), 0) / 
             SUM(p.premium_amount) * 100, 2) > 60  THEN 'Medium'
        ELSE 'Low'
    END                                                             AS risk_level
FROM policies p
LEFT JOIN (
    SELECT policy_id, 
           claim_id,
           SUM(claim_amount) AS total_claim
    FROM claims
    where status='Approved'
    GROUP BY policy_id, claim_id
) c ON c.policy_id = p.policy_id
GROUP BY p.policy_type
ORDER BY loss_ratio_pct DESC;


--Customers & Avg Premium by City

SELECT 
    a.region,
    COUNT(DISTINCT cu.customer_id)   AS customer_count,
    COUNT(DISTINCT p.policy_id)      AS total_policies,
    ROUND(AVG(p.premium_amount), 2)  AS avg_premium,
    SUM(p.premium_amount)            AS total_premium
FROM agents a
JOIN policies p  ON p.agent_id = a.agent_id
JOIN customers cu ON cu.customer_id = p.customer_id
GROUP BY a.region
ORDER BY customer_count DESC;


--Age group by most used policy types and claims
WITH age_policy_counts AS (
    SELECT 
        CASE 
            WHEN cu.age BETWEEN 18 AND 25 THEN '18-25'
            WHEN cu.age BETWEEN 26 AND 35 THEN '26-35'
            WHEN cu.age BETWEEN 36 AND 45 THEN '36-45'
            WHEN cu.age BETWEEN 46 AND 55 THEN '46-55'
            WHEN cu.age BETWEEN 56 AND 65 THEN '56-65'
            ELSE '65+'
        END                          AS age_group,
        p.policy_type,
        c.claim_reason,
        COUNT(DISTINCT p.policy_id)  AS policy_count,
        COUNT(DISTINCT c.claim_id)   AS claim_count,
        ROUND(AVG(c.claim_amount),2) AS avg_claim_amount
    FROM customers cu
    JOIN policies p  ON p.customer_id = cu.customer_id
    LEFT JOIN claims c ON c.policy_id = p.policy_id
    WHERE c.status = 'Approved' OR c.status IS NULL
    GROUP BY 
        CASE 
            WHEN cu.age BETWEEN 18 AND 25 THEN '18-25'
            WHEN cu.age BETWEEN 26 AND 35 THEN '26-35'
            WHEN cu.age BETWEEN 36 AND 45 THEN '36-45'
            WHEN cu.age BETWEEN 46 AND 55 THEN '46-55'
            WHEN cu.age BETWEEN 56 AND 65 THEN '56-65'
            ELSE '65+'
        END,
        p.policy_type,
        c.claim_reason
),
ranked_policy AS (
    SELECT 
        age_group,
        policy_type,
        claim_reason,
        policy_count,
        claim_count,
        avg_claim_amount,
        RANK() OVER (PARTITION BY age_group ORDER BY policy_count DESC)  AS policy_rnk,
        RANK() OVER (PARTITION BY age_group ORDER BY claim_count DESC)   AS claim_rnk
    FROM age_policy_counts
)
SELECT 
    age_group,
    MAX(CASE WHEN policy_rnk = 1 THEN policy_type  END) AS most_used_policy,
    MAX(CASE WHEN policy_rnk = 1 THEN policy_count END) AS policy_count,
    MAX(CASE WHEN claim_rnk  = 1 THEN claim_reason END) AS most_common_claim,
    MAX(CASE WHEN claim_rnk  = 1 THEN claim_count  END) AS claim_count,
    MAX(CASE WHEN claim_rnk  = 1 THEN avg_claim_amount END) AS avg_claim_amount
FROM ranked_policy
GROUP BY age_group
ORDER BY age_group;

-- Payment method analysis
SELECT 
    payment_method,
    COUNT(*)              AS payment_count,
    SUM(amount)           AS total_amount,
    ROUND(AVG(amount), 2) AS avg_payment
FROM payments
GROUP BY payment_method
ORDER BY total_amount DESC;