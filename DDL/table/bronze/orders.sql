-- Databricks notebook source
CREATE TABLE ecommerce.bronze.orders (
  order_id STRING,
  customer_id STRING,
  order_status STRING,
  order_purchase_timestamp STRING,
  order_approved_at STRING,
  order_delivered_carrier_date STRING,
  order_delivered_customer_date STRING,
  order_estimated_delivery_date STRING,
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
