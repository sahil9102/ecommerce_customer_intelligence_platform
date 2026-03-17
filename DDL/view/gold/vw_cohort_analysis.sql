-- Databricks notebook source
CREATE VIEW gold.vw_cohort_analysis (
  cohort_month,
  cohort_size,
  months_since_acquisition,
  activity_month,
  active_customers,
  retention_rate_pct,
  customers_lost_vs_prior_month)
WITH SCHEMA COMPENSATION
AS WITH 
filtered_orders AS (
    -- Fix: exclude partial edge months with unreliable data
    SELECT *
    FROM ecommerce.silver.vw_cln_ltst_orders
    WHERE DATE_FORMAT(order_purchase_timestamp, 'yyyy-MM') NOT IN ('2016-09', '2016-12', '2018-09', '2018-10')
),

customer_cohorts AS (
    -- Use customer_unique_id as the true customer identifier
    -- First order date = acquisition date
    SELECT
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), 'yyyy-MM') AS cohort_month,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM filtered_orders o
    JOIN ecommerce.silver.vw_cln_ltst_customers c 
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),

customer_activity AS (
    -- All months a real customer placed any order
    -- Deduped at customer_unique_id + activity_month grain
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS activity_month
    FROM filtered_orders o
    JOIN ecommerce.silver.vw_cln_ltst_customers c 
        ON o.customer_id = c.customer_id
),

cohort_activity AS (
    SELECT
        cc.cohort_month,
        ca.activity_month,

        -- Months since acquisition (0 = acquisition month itself)
        (
          (YEAR(TO_DATE(CONCAT(ca.activity_month, '-01'))) - YEAR(TO_DATE(CONCAT(cc.cohort_month, '-01')))) * 12
          + (MONTH(TO_DATE(CONCAT(ca.activity_month, '-01'))) - MONTH(TO_DATE(CONCAT(cc.cohort_month, '-01'))))
        ) AS months_since_acquisition,
        COUNT(DISTINCT cc.customer_unique_id) AS active_customers

    FROM customer_cohorts   cc
    LEFT JOIN customer_activity ca 
        ON cc.customer_unique_id = ca.customer_unique_id
    GROUP BY
        1, 2, 3
),

cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(customer_unique_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
)

SELECT
    ca.cohort_month,
    cs.cohort_size,
    ca.months_since_acquisition,
    ca.activity_month,
    ca.active_customers,

    -- Retention rate % vs original cohort size
    ROUND(try_divide(ca.active_customers, cs.cohort_size) * 100, 5) AS retention_rate_pct,

    -- Customers lost compared to previous month in same cohort
    ca.active_customers - LAG(ca.active_customers) OVER (PARTITION BY ca.cohort_month ORDER BY ca.months_since_acquisition) AS customers_lost_vs_prior_month

FROM cohort_activity ca
LEFT JOIN cohort_sizes cs 
    ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.months_since_acquisition
