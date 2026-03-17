-- Databricks notebook source
CREATE TABLE ecommerce.gold.enriched_reviews (
  review_id STRING,
  order_id STRING,
  review_score INT,
  review_comment_title STRING,
  review_comment_message STRING,
  review_creation_date TIMESTAMP,
  review_answer_timestamp TIMESTAMP,
  days_to_review_after_delivery INT,
  review_response_lag_hrs DECIMAL(38,18),
  sentiment STRING,
  has_comment INT,
  is_low_score INT,
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
