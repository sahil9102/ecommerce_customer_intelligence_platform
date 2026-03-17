-- Databricks notebook source
CREATE VIEW silver.vw_cln_ltst_sellers (
  seller_zip_code_prefix,
  seller_id,
  seller_city,
  seller_state,
  file_name,
  partition,
  creation_timestamp,
  updation_timestamp,
  job_run,
  parent_job_run)
WITH SCHEMA COMPENSATION
AS (
    select * except (bad_record_flag, bad_record_reason) from ecommerce.silver.sellers where bad_record_flag = false
)
