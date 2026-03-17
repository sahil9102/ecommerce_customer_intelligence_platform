-- Databricks notebook source
CREATE VIEW silver.vw_payments_agg (
  order_id,
  total_payment_value,
  total_payment_installments,
  num_payment_types_used,
  max_installments,
  credit_card_value,
  boleto_value,
  voucher_value,
  debit_card_value,
  is_installment,
  is_multi_payment,
  pct_credit_card)
WITH SCHEMA COMPENSATION
AS SELECT
    order_id,
    SUM(payment_value)::decimal(38, 18) AS total_payment_value,
    COUNT(payment_sequential) AS total_payment_installments,
    COUNT(DISTINCT payment_type) AS num_payment_types_used,
    MAX(payment_installments) AS max_installments,

    -- Payment type breakdown
    SUM(CASE WHEN payment_type = 'credit_card' THEN payment_value ELSE 0 END)::decimal(38, 18) AS credit_card_value,
    SUM(CASE WHEN payment_type = 'boleto' THEN payment_value ELSE 0 END)::decimal(38, 18) AS boleto_value,
    SUM(CASE WHEN payment_type = 'voucher' THEN payment_value ELSE 0 END)::decimal(38, 18) AS voucher_value,
    SUM(CASE WHEN payment_type = 'debit_card' THEN payment_value ELSE 0 END)::decimal(38, 18) AS debit_card_value,

    -- Derived flags
    CASE WHEN max_installments > 1 THEN 1 ELSE 0 END AS is_installment,
    CASE WHEN num_payment_types_used > 1 THEN 1 ELSE 0 END AS is_multi_payment,

    -- Credit card share
    ROUND(try_divide(credit_card_value, total_payment_value) * 100, 5)::decimal(38, 18) AS pct_credit_card
FROM ecommerce.silver.vw_cln_ltst_order_payments
GROUP BY order_id
