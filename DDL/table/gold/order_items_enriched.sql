-- Databricks notebook source
CREATE TABLE ecommerce.gold.order_items_enriched (
  order_id STRING,
  order_item_id INT,
  product_id STRING,
  seller_id STRING,
  shipping_limit_date TIMESTAMP,
  price DECIMAL(38,18),
  freight_value DECIMAL(38,18),
  category_english STRING,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT,
  product_volume_cm3 INT,
  seller_city STRING,
  seller_state STRING,
  seller_total_orders BIGINT,
  seller_avg_price DECIMAL(38,18),
  seller_total_revenue DECIMAL(38,18),
  item_total_revenue DECIMAL(38,18),
  freight_pct_of_revenue DECIMAL(38,18),
  is_high_value_item INT,
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
