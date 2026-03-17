-- Databricks notebook source
CREATE TABLE ecommerce.gold.model_registry (
  model_name STRING NOT NULL,
  model_type STRING,
  target_col STRING,
  source_view STRING,
  run_id STRING NOT NULL,
  model_uri STRING,
  mlflow_version STRING,
  auc_roc DOUBLE,
  f1_score DOUBLE,
  precision_score DOUBLE,
  recall_score DOUBLE,
  cv_auc_mean DOUBLE,
  cv_auc_std DOUBLE,
  best_threshold DOUBLE,
  score_col STRING,
  label_col STRING,
  feature_cols STRING,
  primary_keys STRING,
  job_id STRING,
  parent_job_id STRING,
  partition STRING,
  status STRING,
  registered_at TIMESTAMP,
  updated_at TIMESTAMP,
  retired_at TIMESTAMP,
  registered_by STRING)
USING delta
COMMENT 'Model registry table — tracks best MLflow run per model, used by inference pipelines to load correct model version'
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
