-- Databricks notebook source
CREATE VIEW silver.reviews_clean (
  review_id,
  order_id,
  review_score,
  review_comment_title,
  review_comment_message,
  review_creation_date,
  review_answer_timestamp,
  days_to_review_after_delivery,
  review_response_lag_hrs,
  sentiment,
  has_comment,
  is_low_score)
WITH SCHEMA COMPENSATION
AS SELECT
    r.review_id,
    r.order_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp,

    -- Review lag from order events
    DATEDIFF(r.review_creation_date, o.order_delivered_customer_date) AS days_to_review_after_delivery,

    (UNIX_TIMESTAMP(r.review_answer_timestamp) - UNIX_TIMESTAMP(r.review_creation_date)) / 3600 AS review_response_lag_hrs,

    -- Sentiment bucket
    CASE
        WHEN r.review_score >= 4 THEN 'positive'
        WHEN r.review_score =  3 THEN 'neutral'
        ELSE 'negative'
    END AS sentiment,

    -- Flags
    CASE WHEN r.review_comment_message IS NOT NULL THEN 1 ELSE 0 END AS has_comment,

    CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END AS is_low_score

FROM ecommerce.silver.vw_cln_ltst_order_reviews r
LEFT JOIN ecommerce.silver.vw_cln_ltst_orders o ON r.order_id = o.order_id
