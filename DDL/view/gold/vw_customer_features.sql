-- Databricks notebook source
CREATE VIEW gold.vw_customer_features (
  customer_unique_id,
  customer_state,
  customer_city,
  recency_days,
  frequency,
  monetary,
  R_score,
  F_score,
  M_score,
  RFM_score,
  rfm_segment,
  churn_label,
  is_inactive_90d,
  clv_total_spend,
  clv_per_active_month,
  annualised_clv,
  clv_calculation_method,
  clv_next_90d_estimate,
  avg_order_value,
  max_order_value,
  avg_delivery_days,
  avg_delay_days,
  late_order_rate,
  late_orders,
  avg_review_score,
  low_score_reviews,
  reviews_with_comment,
  avg_pct_credit_card,
  avg_installments,
  installment_orders,
  freight_to_spend_ratio,
  total_items_purchased,
  avg_items_per_order,
  avg_categories_per_order,
  customer_tenure_days,
  active_months,
  avg_spend_per_month,
  is_repeat_customer,
  first_order_date,
  last_order_date)
WITH SCHEMA COMPENSATION
AS WITH reference_date AS (
    SELECT MAX(order_purchase_timestamp) AS ref_date
    FROM ecommerce.silver.vw_cln_ltst_orders
),

rfm_raw AS (
    SELECT
        coh.customer_unique_id,
        coh.customer_state,
        coh.customer_city,

        -- Recency  
        DATEDIFF(r.ref_date, coh.last_order_date)               AS recency_days,

        -- Frequency 
        coh.total_orders                                        AS frequency,

        -- Monetary
        coh.total_spend                                         AS monetary,

        -- Order behaviour 
        coh.avg_order_value,
        coh.max_order_value,
        coh.avg_delivery_days,
        coh.avg_delay_days,
        coh.late_orders,
        coh.late_order_rate,
        coh.delivered_orders,

        -- Payment behaviour
        coh.avg_pct_credit_card,
        coh.installment_orders,
        coh.avg_installments,
        coh.total_freight_paid,
        coh.freight_to_spend_ratio,

        -- Product behaviour
        coh.total_items_purchased,
        coh.avg_items_per_order,
        coh.total_category_touches,

        -- Review behaviour 
        coh.avg_review_score,
        coh.reviews_with_comment,
        coh.low_score_reviews,

        -- Tenure
        coh.customer_tenure_days,
        coh.active_months,
        coh.avg_spend_per_month,
        coh.first_order_date,
        coh.last_order_date,

        r.ref_date,
        coh.total_orders,
        coh.total_spend

    FROM ecommerce.gold.customer_order_history coh
    CROSS JOIN reference_date r
),

rfm_scored AS (
    SELECT
        *,

        -- RFM Quintile Scoring (1=worst, 5=best)
        NTILE(5) OVER (ORDER BY recency_days DESC)              AS R_score,
        NTILE(5) OVER (ORDER BY frequency ASC)                  AS F_score,
        NTILE(5) OVER (ORDER BY monetary ASC)                   AS M_score

    FROM rfm_raw
),

rfm_labeled AS (
    SELECT
        *,

        -- Composite RFM Score
        R_score + F_score + M_score                             AS RFM_score,

        -- RFM Segment Label
        CASE
            WHEN R_score + F_score + M_score >= 12 THEN 'Champions'
            WHEN R_score + F_score + M_score >= 9  THEN 'Loyal Customers'
            WHEN R_score + F_score + M_score >= 7  THEN 'Potential Loyalists'
            WHEN R_score + F_score + M_score >= 5  THEN 'At Risk'
            ELSE                                        'Lost'
        END                                                     AS rfm_segment,

        -- ── Churn Label (FIXED) ───────────────────────────────────────
        -- Multi-order customers: churned if silent for 90+ days
        -- Single-order customers: churned only if 180+ days ago
        --   (gives them fair window to return before being flagged)
        -- Recently acquired (< 90 days): never flagged as churned
        -- Replace churn_label and is_inactive_90d in rfm_labeled CTE:

        -- ── Observation cutoff: customers acquired before this date ──────────────
        -- Use Jan 2018 as cutoff — gives at least 90 days of prediction window
        -- before dataset ends (Aug 2018)

        -- Customers acquired after Jan 2018 are too new → excluded from churn target
        -- by setting churn_label = NULL (model will drop these rows)

        CASE
            -- Too recently acquired — no prediction window → exclude
            WHEN first_order_date >= '2018-01-01'
                THEN NULL

            -- Repeat buyers: churned if silent 90+ days before dataset end
            WHEN total_orders >= 2
            AND DATEDIFF(ref_date, last_order_date) > 90
                THEN 1

            -- Repeat buyers: active within 90 days = not churned
            WHEN total_orders >= 2
            AND DATEDIFF(ref_date, last_order_date) <= 90
                THEN 0

            -- Single-order buyers: churned if 180+ days silent
            -- AND had enough time to return (ordered before Jul 2017)
            WHEN total_orders = 1
            AND first_order_date < '2017-07-01'
            AND DATEDIFF(ref_date, last_order_date) > 180
                THEN 1

            -- Single-order buyers: ordered recently enough → not churned yet
            WHEN total_orders = 1
            AND first_order_date >= '2017-07-01'
                THEN 0

            ELSE 0
        END                                                         AS churn_label,

        -- Original 90-day inactivity — kept as a feature
        CASE
            WHEN DATEDIFF(ref_date, last_order_date) > 90 THEN 1
            ELSE 0
        END                                                         AS is_inactive_90d,

        -- ── CLV Targets ───────────────────────────────────────────────

        -- 1. Raw total spend — no nulls, base CLV
        CAST(total_spend AS DOUBLE)                             AS clv_total_spend,

        -- 2. Spend per active month — normalised across tenures
        CAST(
            ROUND(total_spend / NULLIF(active_months, 0), 2)
        AS DOUBLE)                                              AS clv_per_active_month,

        -- 3. Annualised CLV — tenure-based for repeat buyers,
        --    spend proxy (×4) for single-order customers
        CAST(
            CASE
                WHEN customer_tenure_days > 0
                    THEN ROUND(total_spend / customer_tenure_days * 365, 2)
                ELSE
                    ROUND(total_spend * 4, 2)
            END
        AS DOUBLE)                                              AS annualised_clv,

        -- 4. CLV calculation method flag
        CASE
            WHEN customer_tenure_days > 0 THEN 'tenure_based'
            ELSE                               'spend_proxy'
        END                                                     AS clv_calculation_method,

        -- 5. Next 90 day CLV estimate — ML regression target
        -- Replace clv_next_90d_estimate in rfm_labeled CTE:
        CAST(
            LEAST(
                ROUND(
                    CASE
                        WHEN total_orders >= 2
                        AND DATEDIFF(ref_date, last_order_date) <= 90
                            THEN avg_order_value
                                * (total_orders / NULLIF(customer_tenure_days, 0) * 90)
                        WHEN total_orders >= 2
                            THEN avg_order_value * 0.5
                        ELSE
                            avg_order_value * 0.1
                    END
                , 2),
                500.0   -- cap at 500 BRL (reasonable 90-day CLV ceiling for Olist)
            )
        AS DOUBLE)                                          AS clv_next_90d_estimate,

        -- Breadth of category engagement
        CAST(
            ROUND(total_category_touches / NULLIF(total_orders, 0), 2)
        AS DOUBLE)                                              AS avg_categories_per_order,

        -- Loyalty flag
        CASE
            WHEN total_orders >= 3 THEN 1
            ELSE 0
        END                                                     AS is_repeat_customer

    FROM rfm_scored
)

SELECT
    -- Identity
    customer_unique_id,
    customer_state,
    customer_city,

    -- Core RFM
    recency_days,
    frequency,
    CAST(monetary               AS DOUBLE)                      AS monetary,
    R_score,
    F_score,
    M_score,
    RFM_score,
    rfm_segment,

    -- ML Targets
    churn_label,
    is_inactive_90d,
    clv_total_spend,
    clv_per_active_month,
    annualised_clv,
    clv_calculation_method,
    clv_next_90d_estimate,

    -- Behavioural Features
    CAST(avg_order_value        AS DOUBLE)                      AS avg_order_value,
    CAST(max_order_value        AS DOUBLE)                      AS max_order_value,
    CAST(avg_delivery_days      AS DOUBLE)                      AS avg_delivery_days,
    CAST(avg_delay_days         AS DOUBLE)                      AS avg_delay_days,
    CAST(late_order_rate        AS DOUBLE)                      AS late_order_rate,
    late_orders,
    CAST(avg_review_score       AS DOUBLE)                      AS avg_review_score,
    low_score_reviews,
    reviews_with_comment,

    -- Payment Features
    CAST(avg_pct_credit_card    AS DOUBLE)                      AS avg_pct_credit_card,
    CAST(avg_installments       AS DOUBLE)                      AS avg_installments,
    installment_orders,
    CAST(freight_to_spend_ratio AS DOUBLE)                      AS freight_to_spend_ratio,

    -- Product Features
    total_items_purchased,
    CAST(avg_items_per_order    AS DOUBLE)                      AS avg_items_per_order,
    CAST(avg_categories_per_order AS DOUBLE)                    AS avg_categories_per_order,

    -- Tenure & Activity
    customer_tenure_days,
    active_months,
    CAST(avg_spend_per_month    AS DOUBLE)                      AS avg_spend_per_month,
    is_repeat_customer,
    first_order_date,
    last_order_date

FROM rfm_labeled
