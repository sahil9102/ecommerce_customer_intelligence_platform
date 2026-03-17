-- Databricks notebook source
CREATE TABLE ecommerce.silver.sellers (
  seller_zip_code_prefix STRING,
  seller_id STRING,
  seller_city STRING,
  seller_state STRING,
  file_name STRING,
  partition STRING,
  creation_timestamp TIMESTAMP,
  updation_timestamp TIMESTAMP,
  bad_record_flag STRING,
  bad_record_reason STRING,
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
