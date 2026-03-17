-- Databricks notebook source
CREATE VIEW bronze.vw_order_payments (
  order_id,
  payment_sequential,
  payment_type,
  payment_installments,
  payment_value,
  file_name,
  partition)
WITH SCHEMA COMPENSATION
AS (
  select 
    try_Cast(order_id as string) as order_id,
    try_Cast(payment_sequential as int) as payment_sequential,
    try_Cast(payment_type as string) as payment_type,
    try_Cast(payment_installments as int) as payment_installments,
    try_Cast(payment_value as double) as payment_value,
    file_name,
    partition
  from bronze.order_payments
)
