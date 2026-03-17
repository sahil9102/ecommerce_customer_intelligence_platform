-- Databricks notebook source
CREATE VIEW bronze.vw_product_category_name_translation (
  product_category_name,
  product_category_name_english,
  file_name,
  partition)
WITH SCHEMA COMPENSATION
AS (
  select 
    try_Cast(product_category_name as string) as product_category_name,
    try_Cast(product_category_name_english as string) as product_category_name_english,
    file_name,
    partition
  from bronze.product_category_name_translation
)
