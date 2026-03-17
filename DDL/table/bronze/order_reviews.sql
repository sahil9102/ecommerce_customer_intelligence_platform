-- Databricks notebook source
CREATE TABLE ecommerce.bronze.order_reviews (
  review_id STRING,
  order_id STRING,
  review_score STRING,
  review_comment_title STRING,
  review_comment_message STRING,
  review_creation_date STRING,
  review_answer_timestamp STRING,
  file_name STRING,
  creation_timestamp TIMESTAMP,
  updation_timestamp TIMESTAMP,
  partition STRING,
  job_run STRING,
  parent_job_run STRING)
USING delta
PARTITIONED BY (partition)
COLLATION 'UTF8_BINARY'
TBLPROPERTIES (
  'delta.enableDeletionVectors' = 'true',
  'delta.feature.appendOnly' = 'supported',
  'delta.feature.deletionVectors' = 'supported',
  'delta.feature.invariants' = 'supported',
  'delta.minReaderVersion' = '3',
  'delta.minWriterVersion' = '7',
  'delta.parquet.compression.codec' = 'zstd')
