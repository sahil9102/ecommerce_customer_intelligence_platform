-- Databricks notebook source
CREATE VIEW bronze.vw_customers (
  customer_id,
  customer_unique_id,
  customer_zip_code_prefix,
  customer_city,
  customer_state,
  file_name,
  partition)
WITH SCHEMA COMPENSATION
AS (
  select 
    try_Cast(customer_id as string) as customer_id,
    try_Cast(customer_unique_id as string) as customer_unique_id,
    try_Cast(customer_zip_code_prefix as string) as customer_zip_code_prefix,
    try_Cast(customer_city as string) as customer_city,
    try_Cast(customer_state as string) as customer_state,
    file_name,
    partition
  from bronze.customers
)
