-- Databricks notebook source
CREATE VIEW bronze.vw_geolocation (
  geolocation_zip_code_prefix,
  geolocation_lat,
  geolocation_lng,
  geolocation_city,
  geolocation_state,
  file_name,
  partition)
WITH SCHEMA COMPENSATION
AS (
  select 
    try_Cast(geolocation_zip_code_prefix as string) as geolocation_zip_code_prefix,
    try_Cast(geolocation_lat as double) as geolocation_lat,
    try_Cast(geolocation_lng as double) as geolocation_lng,
    try_Cast(geolocation_city as string) as geolocation_city,
    try_Cast(geolocation_state as string) as geolocation_state,
    file_name,
    partition
  from bronze.geolocation
)
