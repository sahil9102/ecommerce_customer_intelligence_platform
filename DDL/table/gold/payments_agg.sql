-- Databricks notebook source
CREATE TABLE ecommerce.gold.payments_agg (
  order_id STRING,
  total_payment_value DECIMAL(38,18),
  total_payment_installments BIGINT,
  num_payment_types_used BIGINT,
  max_installments INT,
  credit_card_value DECIMAL(38,18),
  boleto_value DECIMAL(38,18),
  voucher_value DECIMAL(38,18),
  debit_card_value DECIMAL(38,18),
  is_installment INT,
  is_multi_payment INT,
  pct_credit_card DECIMAL(38,18),
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
