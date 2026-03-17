-- Databricks notebook source
CREATE TABLE ecommerce.gold.clv_predictions (
  customer_unique_id STRING NOT NULL,
  customer_state STRING,
  customer_city STRING,
  predicted_clv_90d DOUBLE,
  clv_tier STRING,
  log_transformed STRING,
  model_name STRING,
  model_version STRING,
  prediction_date STRING,
  job_id STRING,
  partition STRING)
USING delta
COMMENT 'Daily CLV predictions — batch inference pipeline'
COLLATION 'UTF8_BINARY'
TBLPROPERTIES (
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.enableDeletionVectors' = 'true',
  'delta.enableRowTracking' = 'true',
  'delta.feature.appendOnly' = 'supported',
  'delta.feature.deletionVectors' = 'supported',
  'delta.feature.domainMetadata' = 'supported',
  'delta.feature.invariants' = 'supported',
  'delta.feature.rowTracking' = 'supported',
  'delta.minReaderVersion' = '3',
  'delta.minWriterVersion' = '7',
  'delta.parquet.compression.codec' = 'zstd')
