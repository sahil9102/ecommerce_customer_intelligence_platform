-- Databricks notebook source
CREATE VIEW bronze.vw_order_items (
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date,
  price,
  freight_value,
  file_name,
  partition)
WITH SCHEMA COMPENSATION
AS (
  select 
    try_Cast(order_id as string) as order_id,
    try_Cast(order_item_id as int) as order_item_id,
    try_Cast(product_id as string) as product_id,
    try_Cast(seller_id as string) as seller_id,
    try_to_timestamp(shipping_limit_date, "yyyy-MM-dd HH:mm:ss") as shipping_limit_date,
    try_Cast(price as double) as price,
    try_Cast(freight_value as double) as freight_value,
    file_name,
    partition
  from bronze.order_items
)
