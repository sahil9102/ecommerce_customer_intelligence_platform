-- Databricks notebook source
CREATE VIEW silver.vw_cln_ltst_products (
  product_id,
  product_category_name,
  product_name_length,
  product_description_length,
  product_photos_qty,
  product_weight_g,
  product_length_cm,
  product_height_cm,
  product_width_cm,
  file_name,
  partition,
  creation_timestamp,
  updation_timestamp,
  job_run,
  parent_job_run)
WITH SCHEMA COMPENSATION
AS (
    select * except (bad_record_flag, bad_record_reason) from ecommerce.silver.products where bad_record_flag = false
)
