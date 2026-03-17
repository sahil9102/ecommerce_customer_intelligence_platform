-- Databricks notebook source
CREATE TABLE ecommerce.gold.customer_segments (
  customer_unique_id STRING NOT NULL,
  customer_state STRING,
  customer_city STRING,
  cluster_id INT,
  segment_name STRING,
  centroid_distance DOUBLE,
  k_used INT,
  silhouette_score DOUBLE,
  model_name STRING,
  model_version STRING,
  segmentation_date STRING,
  job_id STRING,
  partition STRING)
USING delta
COMMENT 'Customer segmentation labels — K-Means clustering pipeline'
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
