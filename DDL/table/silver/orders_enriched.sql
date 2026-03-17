-- Databricks notebook source
CREATE VIEW silver.orders_enriched (
  order_id,
  customer_id,
  customer_unique_id,
  customer_state,
  customer_city,
  lat,
  lng,
  order_status,
  order_purchase_timestamp,
  order_approved_at,
  order_delivered_carrier_date,
  order_delivered_customer_date,
  order_estimated_delivery_date,
  delivery_delay_days,
  actual_delivery_days,
  is_late,
  approval_time_hrs,
  order_purchase_month,
  order_purchase_dayofweek,
  order_purchase_hour,
  is_delivered)
WITH SCHEMA COMPENSATION
AS WITH geo_agg AS (
    -- One row per zip code with averaged lat/lng
    SELECT
        geolocation_zip_code_prefix,
        AVG(geolocation_lat) AS lat,
        AVG(geolocation_lng) AS lng,
        FIRST(geolocation_city) AS city,
        FIRST(geolocation_state) AS state
    FROM ecommerce.silver.vw_cln_ltst_geolocation
    GROUP BY geolocation_zip_code_prefix
),

customers_geo AS (
    SELECT
        c.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        g.lat,
        g.lng
    FROM ecommerce.silver.vw_cln_ltst_customers c
    LEFT JOIN geo_agg g
        ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
)

SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    c.lat,
    c.lng,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- Delivery metrics
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delivery_delay_days,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS actual_delivery_days,
    CASE WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0 THEN 1 ELSE 0 END AS is_late,

    -- Approval speed
    (UNIX_TIMESTAMP(o.order_approved_at) - UNIX_TIMESTAMP(o.order_purchase_timestamp)) / 3600 AS approval_time_hrs,

    -- Time dimensions
    DATE_FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_purchase_month,
    DAYOFWEEK(o.order_purchase_timestamp) AS order_purchase_dayofweek,
    HOUR(o.order_purchase_timestamp) AS order_purchase_hour,

    -- Status flag
    CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END AS is_delivered

FROM ecommerce.silver.vw_cln_ltst_orders o
LEFT JOIN customers_geo c ON o.customer_id = c.customer_id
