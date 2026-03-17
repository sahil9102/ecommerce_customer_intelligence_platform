-- Databricks notebook source
CREATE TABLE ecommerce.gold.orders_enriched (
  order_id STRING,
  customer_id STRING,
  customer_unique_id STRING,
  customer_state STRING,
  customer_city STRING,
  lat DOUBLE,
  lng DOUBLE,
  order_status STRING,
  order_purchase_timestamp TIMESTAMP,
  order_approved_at TIMESTAMP,
  order_delivered_carrier_date TIMESTAMP,
  order_delivered_customer_date TIMESTAMP,
  order_estimated_delivery_date TIMESTAMP,
  delivery_delay_days INT,
  actual_delivery_days INT,
  is_late INT,
  approval_time_hrs DECIMAL(38,18),
  order_purchase_month STRING,
  order_purchase_dayofweek INT,
  order_purchase_hour INT,
  is_delivered INT,
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
