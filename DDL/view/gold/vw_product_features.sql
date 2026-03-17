-- Databricks notebook source
CREATE VIEW gold.vw_product_features (
  product_id,
  category_english,
  product_weight_g,
  product_volume_cm3,
  total_orders,
  total_units_sold,
  total_revenue,
  avg_price,
  min_price,
  max_price,
  price_stddev,
  num_sellers,
  avg_freight,
  avg_freight_pct,
  avg_review_score,
  total_reviews,
  low_score_count,
  reviews_with_comment,
  low_score_rate,
  category_avg_revenue,
  category_total_units,
  revenue_vs_category_avg,
  is_high_value_product,
  sales_velocity_tier)
WITH SCHEMA COMPENSATION
AS WITH product_orders AS (
    SELECT
        i.product_id,
        i.category_english,
        i.product_weight_g,
        i.product_volume_cm3,

        -- Sales velocity 
        COUNT(DISTINCT i.order_id) AS total_orders,
        COUNT(i.order_item_id) AS total_units_sold,
        SUM(i.price) AS total_revenue,
        AVG(i.price) AS avg_price,
        MIN(i.price) AS min_price,
        MAX(i.price) AS max_price,
        STDDEV(i.price) AS price_stddev,

        -- Freight metrics
        AVG(i.freight_value) AS avg_freight,
        AVG(i.freight_pct_of_revenue) AS avg_freight_pct,

        --  Seller spread ─
        COUNT(DISTINCT i.seller_id) AS num_sellers,

        --  High value flag ─
        SUM(i.is_high_value_item) AS high_value_units

    FROM ecommerce.gold.order_items_enriched i
    GROUP BY
        i.product_id,
        i.category_english,
        i.product_weight_g,
        i.product_volume_cm3
),

product_reviews AS (
    SELECT
        i.product_id,
        AVG(r.review_score) AS avg_review_score,
        COUNT(r.review_id) AS total_reviews,
        SUM(r.is_low_score) AS low_score_count,
        SUM(r.has_comment) AS reviews_with_comment
    FROM ecommerce.gold.order_items_enriched i
    LEFT JOIN ecommerce.gold.enriched_reviews r 
      ON i.order_id = r.order_id
    GROUP BY i.product_id
),

category_stats AS (
    -- Category-level benchmarks for relative scoring
    SELECT
        category_english,
        AVG(total_revenue) AS category_avg_revenue,
        AVG(avg_price) AS category_avg_price,
        SUM(total_units_sold) AS category_total_units
    FROM product_orders
    GROUP BY category_english
)

SELECT
    po.product_id,
    po.category_english,
    po.product_weight_g,
    po.product_volume_cm3,

    --  Sales metrics ─
    po.total_orders,
    po.total_units_sold,
    po.total_revenue,
    po.avg_price,
    po.min_price,
    po.max_price,
    po.price_stddev,
    po.num_sellers,

    --  Freight metrics ─
    po.avg_freight,
    po.avg_freight_pct,

    --  Review metrics 
    pr.avg_review_score::decimal(38, 18),
    pr.total_reviews,
    pr.low_score_count,
    pr.reviews_with_comment,

    ROUND(try_divide(pr.low_score_count, pr.total_reviews) * 100, 2)::decimal(38, 18) AS low_score_rate,

    --  Category relative metrics ─
    cs.category_avg_revenue,
    cs.category_total_units,

    ROUND(try_divide(po.total_revenue, cs.category_avg_revenue), 5) AS revenue_vs_category_avg,

    --  Product flags ─
    CASE WHEN po.avg_price >= 200 THEN 1 ELSE 0 END AS is_high_value_product,

    CASE
        WHEN po.total_units_sold >= 50 THEN 'High'
        WHEN po.total_units_sold >= 10 THEN 'Medium'
        ELSE 'Low'
    END AS sales_velocity_tier

FROM product_orders po
LEFT JOIN product_reviews pr 
    ON po.product_id = pr.product_id
LEFT JOIN category_stats cs 
    ON po.category_english = cs.category_english
