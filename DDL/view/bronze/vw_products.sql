-- Databricks notebook source
CREATE VIEW bronze.vw_products (
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
  partition)
WITH SCHEMA COMPENSATION
AS (
  select 
    try_Cast(product_id as string) as product_id,
    try_Cast(product_category_name as string) as product_category_name,
    try_Cast(product_name_length as int) as product_name_length,
    try_Cast(product_description_length as int) as product_description_length,
    try_Cast(product_photos_qty as int) as product_photos_qty,
    try_Cast(product_weight_g as int) as product_weight_g,
    try_Cast(product_length_cm as int) as product_length_cm,
    try_Cast(product_height_cm as int) as product_height_cm,
    try_Cast(product_width_cm as int) as product_width_cm,
    file_name,
    partition
  from ecommerce.bronze.products
)
