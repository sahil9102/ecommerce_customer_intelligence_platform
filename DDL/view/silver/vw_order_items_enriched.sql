-- Databricks notebook source
CREATE VIEW silver.vw_order_items_enriched (
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date,
  price,
  freight_value,
  category_english,
  product_weight_g,
  product_length_cm,
  product_height_cm,
  product_width_cm,
  product_volume_cm3,
  seller_city,
  seller_state,
  seller_total_orders,
  seller_avg_price,
  seller_total_revenue,
  item_total_revenue,
  freight_pct_of_revenue,
  is_high_value_item)
WITH SCHEMA COMPENSATION
AS WITH seller_stats AS (
    -- Pre-aggregate seller metrics
    SELECT
        seller_id,
        COUNT(order_id) AS seller_total_orders,
        AVG(price)::decimal(38, 18) AS seller_avg_price,
        SUM(price)::decimal(38, 18) AS seller_total_revenue
    FROM ecommerce.silver.vw_cln_ltst_order_items
    GROUP BY seller_id
),

products_en AS (
    SELECT
        p.product_id,
        p.product_category_name,
        COALESCE(t.product_category_name_english, p.product_category_name) AS category_english,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm
    FROM ecommerce.silver.vw_cln_ltst_products p
    LEFT JOIN ecommerce.silver.vw_cln_ltst_product_category_name_translation t
        ON p.product_category_name = t.product_category_name
)

SELECT
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    i.shipping_limit_date,
    i.price::decimal(38, 18),
    i.freight_value::decimal(38, 18),

    -- Product info
    p.category_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    (p.product_length_cm * p.product_height_cm * p.product_width_cm) AS product_volume_cm3,

    -- Seller info
    s.seller_city,
    s.seller_state,
    st.seller_total_orders,
    st.seller_avg_price,
    st.seller_total_revenue,

    -- Revenue metrics
    (i.price + i.freight_value)::decimal(38, 18) AS item_total_revenue,
    (ROUND(try_divide(i.freight_value, (i.price + i.freight_value) * 100), 5))::decimal(38, 18) AS freight_pct_of_revenue,

    -- Item flags
    (CASE WHEN i.price >= 200 THEN 1 ELSE 0 END) AS is_high_value_item

FROM ecommerce.silver.vw_cln_ltst_order_items i
LEFT JOIN products_en  p  ON i.product_id = p.product_id
LEFT JOIN ecommerce.silver.vw_cln_ltst_sellers s  ON i.seller_id = s.seller_id
LEFT JOIN seller_stats st ON i.seller_id = st.seller_id
