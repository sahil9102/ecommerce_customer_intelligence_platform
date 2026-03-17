-- Databricks notebook source
CREATE VIEW silver.vw_cln_ltst_order_payments (
  order_id,
  payment_sequential,
  payment_type,
  payment_installments,
  payment_value,
  file_name,
  partition,
  creation_timestamp,
  updation_timestamp,
  job_run,
  parent_job_run)
WITH SCHEMA COMPENSATION
AS (
    select * except (bad_record_flag, bad_record_reason) from ecommerce.silver.order_payments where bad_record_flag = false
)
