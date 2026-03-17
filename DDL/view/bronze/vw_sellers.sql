-- Databricks notebook source
CREATE VIEW bronze.vw_sellers (
  seller_zip_code_prefix,
  seller_id,
  seller_city,
  seller_state,
  file_name,
  partition)
WITH SCHEMA COMPENSATION
AS (
  select 
    try_Cast(seller_zip_code_prefix as string) as seller_zip_code_prefix,
    try_Cast(seller_id as string) as seller_id,
    try_Cast(seller_city as string) as seller_city,
    try_Cast(seller_state as string) as seller_state,
    file_name,
    partition
  from bronze.sellers
)
