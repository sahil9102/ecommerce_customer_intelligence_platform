-- Databricks notebook source
CREATE TABLE ecommerce.bronze.sellers (
  seller_id STRING,
  seller_zip_code_prefix STRING,
  seller_city STRING,
  seller_state STRING,
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
