-- Databricks notebook source
CREATE VIEW gold.vw_business_kpis (
  month,
  total_orders,
  active_customers,
  new_customers,
  returning_customers,
  total_revenue,
  avg_order_value,
  revenue_per_customer,
  revenue_mom_growth_pct,
  credit_card_revenue,
  boleto_revenue,
  voucher_revenue,
  installment_orders,
  delivered_orders,
  late_orders,
  late_delivery_rate_pct,
  avg_delivery_days,
  avg_review_score,
  low_score_reviews,
  total_reviews,
  low_score_rate_pct,
  customer_growth_mom_pct)
WITH SCHEMA COMPENSATION
AS WITH monthly_orders AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS month,
        COUNT(DISTINCT o.order_id) AS total_orders,

        -- Fix: use customer_unique_id for true unique customer count
        COUNT(DISTINCT c.customer_unique_id) AS active_customers,

        SUM(o.is_delivered) AS delivered_orders,
        SUM(o.is_late) AS late_orders,
        AVG(o.actual_delivery_days) AS avg_delivery_days
    FROM ecommerce.gold.orders_enriched  o
    JOIN ecommerce.silver.vw_cln_ltst_customers  c 
        ON o.customer_id = c.customer_id
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
),

monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS month,
        SUM(p.total_payment_value) AS total_revenue,
        AVG(p.total_payment_value) AS avg_order_value,
        SUM(p.credit_card_value) AS credit_card_revenue,
        SUM(p.boleto_value) AS boleto_revenue,
        SUM(p.voucher_value) AS voucher_revenue,
        SUM(p.is_installment) AS installment_orders
    FROM ecommerce.gold.orders_enriched   o
    LEFT JOIN ecommerce.gold.payments_agg p 
        ON o.order_id = p.order_id
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
),

monthly_reviews AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS month,
        AVG(r.review_score) AS avg_review_score,
        SUM(r.is_low_score) AS low_score_reviews,
        COUNT(r.review_id) AS total_reviews
    FROM ecommerce.gold.orders_enriched o
    LEFT JOIN ecommerce.gold.vw_enriched_reviews r 
        ON o.order_id = r.order_id
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
),

true_first_orders AS (
    -- Fix: derive first order date per real customer using customer_unique_id
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM ecommerce.silver.vw_cln_ltst_orders o
    JOIN ecommerce.silver.vw_cln_ltst_customers c 
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),

monthly_new_customers AS (
    -- Fix: a customer is "new" only in the month of their very first order
    SELECT
        DATE_FORMAT(first_order_date, 'yyyy-MM') AS month,
        COUNT(customer_unique_id) AS new_customers
    FROM true_first_orders
    GROUP BY DATE_FORMAT(first_order_date, 'yyyy-MM')
)
SELECT
    mo.month,

    -- ── Volume KPIs ───────────────────────────────────────────────
    mo.total_orders,
    mo.active_customers,
    COALESCE(mn.new_customers, 0) AS new_customers,

    -- Fix: returning = total active minus genuinely new this month
    mo.active_customers - COALESCE(mn.new_customers, 0) AS returning_customers,

    -- ── Revenue KPIs ──────────────────────────────────────────────
    mr.total_revenue,
    mr.avg_order_value,
    ROUND(try_divide(mr.total_revenue, mo.active_customers), 5) AS revenue_per_customer,

    -- ── Revenue MoM Growth ────────────────────────────────────────
    ROUND(try_divide(
        (mr.total_revenue - LAG(mr.total_revenue) OVER (ORDER BY mo.month)),
        LAG(mr.total_revenue) OVER (ORDER BY mo.month)) * 100
    , 5) AS revenue_mom_growth_pct,

    -- ── Payment Mix ───────────────────────────────────────────────
    mr.credit_card_revenue,
    mr.boleto_revenue,
    mr.voucher_revenue,
    mr.installment_orders,

    -- ── Operations KPIs ───────────────────────────────────────────
    mo.delivered_orders,
    mo.late_orders,
    ROUND(try_divide(mo.late_orders, mo.delivered_orders) * 100, 5) AS late_delivery_rate_pct,
    mo.avg_delivery_days,

    -- ── Quality KPIs ──────────────────────────────────────────────
    rv.avg_review_score,
    rv.low_score_reviews,
    rv.total_reviews,
    ROUND(try_divide(rv.low_score_reviews, rv.total_reviews) * 100, 5) AS low_score_rate_pct,

    -- ── Customer Growth MoM ───────────────────────────────────────
    ROUND(try_divide(
        (mo.active_customers - LAG(mo.active_customers) OVER (ORDER BY mo.month)),
        LAG(mo.active_customers) OVER (ORDER BY mo.month)) * 100
    , 5) AS customer_growth_mom_pct

FROM monthly_orders mo
LEFT JOIN monthly_revenue mr 
    ON mo.month = mr.month
LEFT JOIN monthly_reviews rv 
    ON mo.month = rv.month
LEFT JOIN monthly_new_customers mn 
    ON mo.month = mn.month
where mo.month NOT IN ('2016-09', '2016-12', '2018-09', '2018-10')
