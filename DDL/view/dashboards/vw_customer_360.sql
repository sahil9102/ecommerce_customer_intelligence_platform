-- Databricks notebook source
CREATE VIEW dashboards.vw_customer_360 (
  customer_unique_id,
  customer_state,
  customer_city,
  recency_days,
  frequency,
  monetary,
  R_score,
  F_score,
  M_score,
  RFM_score,
  rfm_segment,
  avg_order_value,
  avg_review_score,
  late_order_rate,
  customer_tenure_days,
  active_months,
  is_repeat_customer,
  churn_probability,
  churn_label_predicted,
  risk_tier,
  best_threshold,
  churn_prediction_date,
  predicted_clv_90d,
  clv_tier,
  cluster_id,
  segment_name,
  centroid_distance,
  revenue_at_risk_90d)
WITH SCHEMA COMPENSATION
AS SELECT
    cf.customer_unique_id,
    cf.customer_state,
    cf.customer_city,

    -- RFM
    cf.recency_days,
    cf.frequency,
    cf.monetary,
    cf.R_score,
    cf.F_score,
    cf.M_score,
    cf.RFM_score,
    cf.rfm_segment,

    -- Behavioural
    cf.avg_order_value,
    cf.avg_review_score,
    cf.late_order_rate,
    cf.customer_tenure_days,
    cf.active_months,
    cf.is_repeat_customer,

    -- Churn predictions
    cp.churn_probability,
    cp.churn_label_predicted,
    cp.risk_tier,
    cp.best_threshold,
    cp.prediction_date       AS churn_prediction_date,

    -- CLV predictions
    clv.predicted_clv_90d,
    clv.clv_tier,

    -- Segments
    cs.cluster_id,
    case cs.segment_name when "type_3" then "Dissatisfied High Spenders" when "type_2" then "Loyal Champions" when "type_1" then "Standard Buyers" end as segment_name,
    cs.centroid_distance,

    -- Revenue at risk (churn probability × predicted CLV)
    CAST(
        ROUND(cp.churn_probability * clv.predicted_clv_90d, 2)
    AS DOUBLE)               AS revenue_at_risk_90d

FROM ecommerce.gold.vw_customer_features    cf
LEFT JOIN ecommerce.gold.churn_predictions  cp
    ON cf.customer_unique_id = cp.customer_unique_id
    AND cp.prediction_date   = (
        SELECT MAX(prediction_date)
        FROM ecommerce.gold.churn_predictions
    )
LEFT JOIN ecommerce.gold.clv_predictions    clv
    ON cf.customer_unique_id = clv.customer_unique_id
    AND clv.prediction_date  = (
        SELECT MAX(prediction_date)
        FROM ecommerce.gold.clv_predictions
    )
LEFT JOIN ecommerce.gold.customer_segments  cs
    ON cf.customer_unique_id = cs.customer_unique_id
