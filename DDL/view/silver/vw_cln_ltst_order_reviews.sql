-- Databricks notebook source
CREATE VIEW silver.vw_cln_ltst_order_reviews (
  review_id,
  order_id,
  review_score,
  review_comment_title,
  review_comment_message,
  review_creation_date,
  review_answer_timestamp,
  file_name,
  partition,
  creation_timestamp,
  updation_timestamp,
  job_run,
  parent_job_run)
WITH SCHEMA COMPENSATION
AS (
    select * except (bad_record_flag, bad_record_reason) from ecommerce.silver.order_reviews where bad_record_flag = false
)
