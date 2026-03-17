-- Databricks notebook source
CREATE VIEW silver.vw_customer_order_history (
  customer_unique_id,
  customer_state,
  customer_city,
  total_orders,
  delivered_orders,
  late_orders,
  avg_delivery_days,
  avg_delay_days,
  total_spend,
  avg_order_value,
  max_order_value,
  total_freight_paid,
  avg_pct_credit_card,
  installment_orders,
  avg_installments,
  total_items_purchased,
  avg_items_per_order,
  total_category_touches,
  active_months,
  avg_review_score,
  reviews_with_comment,
  low_score_reviews,
  first_order_date,
  last_order_date,
  customer_tenure_days,
  late_order_rate,
  avg_spend_per_month,
  freight_to_spend_ratio)
WITH SCHEMA COMPENSATION
AS WITH items_per_order AS (
    SELECT
        order_id,
        COUNT(order_item_id) AS items_in_order,
        SUM(price) AS order_product_value,
        SUM(freight_value) AS order_freight_value,
        SUM(item_total_revenue) AS order_total_item_revenue,
        COUNT(DISTINCT category_english) AS distinct_categories,
        SUM(is_high_value_item) AS high_value_items_count
    FROM ecommerce.silver.vw_order_items_enriched
    GROUP BY order_id
),

orders_full AS (
    -- Combine all order-level silver tables
    SELECT
        o.order_id,
        o.customer_id,
        o.customer_unique_id,
        o.customer_state,
        o.customer_city,
        o.order_purchase_timestamp,
        o.order_purchase_month,
        o.is_delivered,
        o.is_late,
        o.actual_delivery_days,
        o.delivery_delay_days,

        -- Items
        i.items_in_order,
        i.order_product_value,
        i.order_freight_value,
        i.order_total_item_revenue,
        i.distinct_categories,
        i.high_value_items_count,

        -- Payments
        p.total_payment_value,
        p.pct_credit_card,
        p.is_installment,
        p.max_installments,

        -- Reviews
        r.review_score,
        r.sentiment,
        r.has_comment,
        r.is_low_score,
        r.days_to_review_after_delivery

    FROM ecommerce.silver.vw_orders_enriched o
    LEFT JOIN items_per_order i ON o.order_id = i.order_id
    LEFT JOIN ecommerce.silver.vw_payments_agg p ON o.order_id = p.order_id
    LEFT JOIN ecommerce.silver.vw_enriched_reviews r ON o.order_id = r.order_id
)

SELECT
    customer_unique_id,
    max((order_purchase_timestamp, customer_state)).customer_state as customer_state,
    max((order_purchase_timestamp, customer_city)).customer_city as customer_city,

    -- Order behaviour
    COUNT(order_id) AS total_orders,
    SUM(is_delivered) AS delivered_orders,
    SUM(is_late) AS late_orders,
    AVG(actual_delivery_days) AS avg_delivery_days,
    AVG(delivery_delay_days) AS avg_delay_days,

    -- Spend
    SUM(total_payment_value) AS total_spend,
    AVG(total_payment_value) AS avg_order_value,
    MAX(total_payment_value) AS max_order_value,
    SUM(order_freight_value) AS total_freight_paid,

    -- Payment behaviour
    AVG(pct_credit_card) AS avg_pct_credit_card,
    SUM(is_installment) AS installment_orders,
    AVG(max_installments) AS avg_installments,

    -- Product behaviour
    SUM(items_in_order) AS total_items_purchased,
    AVG(items_in_order) AS avg_items_per_order,
    SUM(distinct_categories) AS total_category_touches,
    COUNT(DISTINCT order_purchase_month) AS active_months,

    -- Review behaviour
    AVG(review_score) AS avg_review_score,
    SUM(has_comment) AS reviews_with_comment,
    SUM(is_low_score) AS low_score_reviews,

    -- Recency / Tenure
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date,

    -- Derived
    DATEDIFF(MAX(order_purchase_timestamp),
    MIN(order_purchase_timestamp)) AS customer_tenure_days,
    ROUND(SUM(is_late) / COUNT(order_id), 4) AS late_order_rate,
    ROUND(try_divide(SUM(total_payment_value), COUNT(DISTINCT order_purchase_month)), 2) AS avg_spend_per_month,
    ROUND(try_divide(SUM(order_freight_value), SUM(total_payment_value)), 4) AS freight_to_spend_ratio

FROM orders_full
GROUP BY
    customer_unique_id
