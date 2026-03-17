-- Databricks notebook source
CREATE VIEW silver.vw_cln_ltst_product_category_name_translation (
  product_category_name,
  product_category_name_english,
  file_name,
  partition,
  creation_timestamp,
  updation_timestamp,
  job_run,
  parent_job_run)
WITH SCHEMA COMPENSATION
AS (
    select * except (bad_record_flag, bad_record_reason) from ecommerce.silver.product_category_name_translation where bad_record_flag = false
)
