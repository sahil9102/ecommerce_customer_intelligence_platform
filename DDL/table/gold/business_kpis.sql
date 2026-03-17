-- Databricks notebook source
CREATE TABLE ecommerce.gold.business_kpis (
  month STRING,
  total_orders BIGINT,
  active_customers BIGINT,
  new_customers BIGINT,
  returning_customers BIGINT,
  total_revenue DECIMAL(38,18),
  avg_order_value DECIMAL(38,22),
  revenue_per_customer DECIMAL(26,5),
  revenue_mom_growth_pct DECIMAL(38,5),
  credit_card_revenue DECIMAL(38,18),
  boleto_revenue DECIMAL(38,18),
  voucher_revenue DECIMAL(38,18),
  installment_orders BIGINT,
  delivered_orders BIGINT,
  late_orders BIGINT,
  late_delivery_rate_pct DOUBLE,
  avg_delivery_days DOUBLE,
  avg_review_score DOUBLE,
  low_score_reviews BIGINT,
  total_reviews BIGINT,
  low_score_rate_pct DOUBLE,
  customer_growth_mom_pct DOUBLE,
  creation_timestamp TIMESTAMP,
  updation_timestamp TIMESTAMP,
  job_run STRING,
  parent_job_run STRING)
USING delta
COLLATION 'UTF8_BINARY'
TBLPROPERTIES (
  'delta.enableDeletionVectors' = 'true',
  'delta.feature.appendOnly' = 'supported',
  'delta.feature.deletionVectors' = 'supported',
  'delta.feature.invariants' = 'supported',
  'delta.minReaderVersion' = '3',
  'delta.minWriterVersion' = '7',
  'delta.parquet.compression.codec' = 'zstd')
