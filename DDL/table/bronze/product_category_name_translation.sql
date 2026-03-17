-- Databricks notebook source
CREATE TABLE ecommerce.bronze.product_category_name_translation (
  product_category_name STRING,
  product_category_name_english STRING,
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
