-- Databricks notebook source
CREATE VIEW bronze.vw_order_reviews (
  review_id,
  order_id,
  review_score,
  review_comment_title,
  review_comment_message,
  review_creation_date,
  review_answer_timestamp,
  file_name,
  partition)
WITH SCHEMA COMPENSATION
AS (
  select 
    try_Cast(review_id as string) as review_id,
    try_Cast(order_id as string) as order_id,
    try_Cast(review_score as int) as review_score,
    try_Cast(review_comment_title as string) as review_comment_title,
    try_Cast(review_comment_message as string) as review_comment_message,
    try_to_timestamp(review_creation_date, "yyyy-MM-dd HH:mm:ss") as review_creation_date,
    try_to_timestamp(review_answer_timestamp, "yyyy-MM-dd HH:mm:ss") as review_answer_timestamp,
    file_name,
    partition
  from ecommerce.bronze.order_reviews
)
