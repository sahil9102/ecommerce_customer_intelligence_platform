-- Databricks notebook source
CREATE TABLE ecommerce.gold.cohort_analysis (
  cohort_month STRING,
  cohort_size BIGINT,
  months_since_acquisition INT,
  activity_month STRING,
  active_customers BIGINT,
  retention_rate_pct DOUBLE,
  customers_lost_vs_prior_month BIGINT,
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
