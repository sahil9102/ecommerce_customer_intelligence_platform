-- Databricks notebook source
CREATE VIEW bronze.vw_orders (
  order_id,
  customer_id,
  order_status,
  order_purchase_timestamp,
  order_approved_at,
  order_delivered_carrier_date,
  order_delivered_customer_date,
  order_estimated_delivery_date,
  file_name,
  partition)
WITH SCHEMA COMPENSATION
AS (
  select 
    try_Cast(order_id as string) as order_id,
    try_Cast(customer_id as string) as customer_id,
    try_Cast(order_status as string) as order_status,
    try_to_timestamp(order_purchase_timestamp, "yyyy-MM-dd HH:mm:ss") as order_purchase_timestamp,
    try_to_timestamp(order_approved_at, "yyyy-MM-dd HH:mm:ss") as order_approved_at,
    try_to_timestamp(order_delivered_carrier_date, "yyyy-MM-dd HH:mm:ss") as order_delivered_carrier_date,
    try_to_timestamp(order_delivered_customer_date, "yyyy-MM-dd HH:mm:ss") as order_delivered_customer_date,
    try_to_timestamp(order_estimated_delivery_date, "yyyy-MM-dd HH:mm:ss") as order_estimated_delivery_date,
    file_name,
    partition
  from bronze.orders
)
