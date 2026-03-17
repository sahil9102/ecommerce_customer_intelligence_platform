-- Databricks notebook source
CREATE VIEW silver.vw_cln_ltst_order_items (
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date,
  price,
  freight_value,
  file_name,
  partition,
  creation_timestamp,
  updation_timestamp,
  job_run,
  parent_job_run)
WITH SCHEMA COMPENSATION
AS (
    select * except (bad_record_flag, bad_record_reason) from ecommerce.silver.order_items where bad_record_flag = false
)
