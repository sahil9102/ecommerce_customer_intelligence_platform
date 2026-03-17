# E-Commerce Customer Intelligence Platform

> A production-grade data engineering and machine learning platform built on **Databricks**, using the **Olist Brazilian E-Commerce** dataset from Kaggle. The platform ingests raw transactional data, transforms it through a Medallion Architecture, engineers features, trains multiple ML models, and serves predictions through automated batch inference pipelines — all orchestrated end-to-end on Databricks.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Dataset](#3-dataset)
4. [Tech Stack](#4-tech-stack)
5. [Project Structure](#5-project-structure)
6. [Data Architecture — Medallion Layers](#6-data-architecture--medallion-layers)
7. [Machine Learning Models](#7-machine-learning-models)
8. [Batch Inference Pipelines](#8-batch-inference-pipelines)
9. [Analytics & Dashboards](#9-analytics--dashboards)
10. [Orchestration](#10-orchestration)
11. [Key Results](#11-key-results)
12. [How to Run](#12-how-to-run)
13. [Design Decisions](#13-design-decisions)

---

## 1. Project Overview

This project solves three core business problems for an e-commerce company:

| Business Question | Approach | Output Table |
|---|---|---|
| Which customers will churn in the next 30 days? | XGBoost Binary Classifier | `gold.churn_predictions` |
| What is each customer's predicted revenue in the next 90 days? | XGBoost + Random Forest Regressor | `gold.clv_predictions` |
| Which behavioural segment does each customer belong to? | K-Means Clustering | `gold.customer_segments` |

All three questions are answered at scale for **96,096 customers** and refreshed daily through automated batch inference pipelines.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    KAGGLE DATASETS (Olist)                          │
│          9 CSV files → Unity Catalog Volume                         │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      BRONZE LAYER (Delta Tables)                    │
│   Raw ingestion — schema enforcement — full history preserved       │
│   10 Delta tables + Bronze views (vw_*) for Silver consumption      │
└────────────────────────────┬────────────────────────────────────────┘
                             │  Bronze views → Silver cleaning views
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      SILVER LAYER (Views + Delta Tables)            │
│   vw_cln_ltst_* views: cleaned, deduplicated, latest records        │
│   Enriched views: joined, computed, business-logic applied          │
│   Delta tables: SCD Type 1 upsert from Silver views (Gold jobs)     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       GOLD LAYER (Delta Tables + Views)             │
│   Enriched Delta tables: orders, items, payments, reviews,          │
│   customer history, features, KPIs, cohort analysis                 │
│   Analytics views: vw_customer_features, vw_customer_360, etc.      │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
┌──────────────────────┐   ┌─────────────────────────┐
│   ML TRAINING        │   │   BATCH INFERENCE        │
│  XGBoost Classifier  │   │  96K customers scored    │
│  XGBoost Regressor   │   │  daily refresh           │
│  K-Means Clustering  │   │  gold.churn_predictions  │
│  MLflow tracking     │   │  gold.clv_predictions    │
│  gold.model_registry │   │  gold.customer_segments  │
└──────────────────────┘   └─────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   DATABRICKS SQL DASHBOARDS                         │
│   5 dashboards: Business KPIs, Churn, CLV, Segments, Customer 360  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Dataset

**Source:** [Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — Kaggle

| File | Bronze Table | Rows | Description |
|---|---|---|---|
| `olist_orders_dataset.csv` | `bronze.orders` | ~100K | Order lifecycle and timestamps |
| `olist_customers_dataset.csv` | `bronze.customers` | ~100K | Customer demographics and zip codes |
| `olist_order_items_dataset.csv` | `bronze.order_items` | ~113K | Line items per order |
| `olist_order_payments_dataset.csv` | `bronze.order_payments` | ~104K | Payment types and installments |
| `olist_order_reviews_dataset.csv` | `bronze.order_reviews` | ~100K | Customer review scores and comments |
| `olist_products_dataset.csv` | `bronze.products` | ~33K | Product dimensions and categories |
| `olist_sellers_dataset.csv` | `bronze.sellers` | ~3K | Seller geography |
| `olist_geolocation_dataset.csv` | `bronze.geolocation` | ~1M | Zip code lat/lng coordinates |
| `product_category_name_translation.csv` | `bronze.product_category_name_translation` | ~71 | Portuguese → English category names |

**Key Dataset Characteristic:** ~97% of customers placed only one order. This shaped every design decision — from churn label definition to the decision to skip ALS collaborative filtering (insufficient interaction data for meaningful recommendations).

---

## 4. Tech Stack

| Layer | Technology |
|---|---|
| Platform | Databricks (Community Edition) |
| Storage | Delta Lake with ACID transactions |
| Data Governance | Unity Catalog + Volumes |
| Compute | Apache Spark (PySpark + Spark SQL) |
| ML Framework | scikit-learn, XGBoost, Spark MLlib |
| Experiment Tracking | MLflow (Databricks Managed) |
| Orchestration | Databricks Notebooks + `dbutils.notebook.run` |
| Dashboards | Databricks SQL Lakeview Dashboards |
| Language | Python 3.12, SQL |
| Data Format | Delta (Bronze/Gold tables), SQL Views (Silver/Gold analytics) |

---

## 5. Project Structure

```
ecommerce_customer_intelligence_platform/
│
├── DDL/
│   ├── table/
│   │   ├── bronze/           ← CREATE TABLE DDL for all Bronze tables
│   │   │   ├── customers.sql
│   │   │   ├── geolocation.sql
│   │   │   ├── order_items.sql
│   │   │   ├── order_payments.sql
│   │   │   ├── order_reviews.sql
│   │   │   ├── orders.sql
│   │   │   ├── product_category_name_translation.sql
│   │   │   ├── products.sql
│   │   │   └── sellers.sql
│   │   ├── silver/           ← CREATE TABLE DDL for Silver Delta tables
│   │   │   ├── customers.sql
│   │   │   ├── geolocation.sql
│   │   │   ├── order_items.sql
│   │   │   ├── order_items_enriched.sql
│   │   │   ├── order_payments.sql
│   │   │   ├── order_reviews.sql
│   │   │   ├── orders.sql
│   │   │   ├── orders_enriched.sql
│   │   │   ├── payments_agg.sql
│   │   │   ├── product_category_name_translation.sql
│   │   │   ├── products.sql
│   │   │   ├── reviews_clean.sql
│   │   │   └── sellers.sql
│   │   ├── gold/             ← CREATE TABLE DDL for Gold Delta tables
│   │   │   ├── business_kpis.sql
│   │   │   ├── churn_predictions.sql
│   │   │   ├── clv_predictions.sql
│   │   │   ├── cohort_analysis.sql
│   │   │   ├── customer_features.sql
│   │   │   ├── customer_order_history.sql
│   │   │   ├── customer_segments.sql
│   │   │   ├── enriched_reviews.sql
│   │   │   ├── model_registry.sql
│   │   │   ├── order_items_enriched.sql
│   │   │   ├── orders_enriched.sql
│   │   │   ├── payments_agg.sql
│   │   │   └── product_features.sql
│   │   └── ml/
│   │       └── model_registry.sql
│   └── view/
│       ├── bronze/           ← Bronze views (vw_*) consumed by Silver ETL
│       │   ├── vw_customers.sql
│       │   ├── vw_geolocation.sql
│       │   ├── vw_order_items.sql
│       │   ├── vw_order_payments.sql
│       │   ├── vw_order_reviews.sql
│       │   ├── vw_orders.sql
│       │   ├── vw_product_category_name_translation.sql
│       │   ├── vw_products.sql
│       │   └── vw_sellers.sql
│       ├── silver/           ← Silver views (cleaning + enrichment)
│       │   ├── vw_cln_ltst_customers.sql
│       │   ├── vw_cln_ltst_geolocation.sql
│       │   ├── vw_cln_ltst_order_items.sql
│       │   ├── vw_cln_ltst_order_payments.sql
│       │   ├── vw_cln_ltst_order_reviews.sql
│       │   ├── vw_cln_ltst_orders.sql
│       │   ├── vw_cln_ltst_product_category_name_translation.sql
│       │   ├── vw_cln_ltst_products.sql
│       │   ├── vw_cln_ltst_sellers.sql
│       │   ├── vw_customer_order_history.sql
│       │   ├── vw_enriched_reviews.sql
│       │   ├── vw_order_items_enriched.sql
│       │   ├── vw_orders_enriched.sql
│       │   └── vw_payments_agg.sql
│       ├── gold/             ← Gold analytics views consumed by ML + dashboards
│       │   ├── vw_business_kpis.sql
│       │   ├── vw_cohort_analysis.sql
│       │   ├── vw_customer_360.sql
│       │   ├── vw_customer_features.sql
│       │   └── vw_product_features.sql
│       └── dashboards/
│           └── vw_customer_360.sql
│
├── ETL/
│   ├── raw_to_bronze         ← Parameterized: CSV → Bronze Delta table
│   ├── bronze_to_silver      ← Parameterized: Bronze → Silver Delta (SCD Type 1)
│   └── scd_type_1            ← Parameterized: Silver/Gold view → Gold Delta (SCD Type 1)
│
├── ML/
│   ├── XGBoost               ← Churn prediction training (job 40001)
│   ├── CLV_regression        ← Customer lifetime value training (job 50002)
│   ├── K_means_clustering    ← Customer segmentation (job 50005)
│   └── batch_inference       ← Generic inference: classification + regression
│
├── orchestration/
│   ├── run_pipeline          ← Master trigger: Workflow 1 → 2 → 3
│   ├── workflow_bronze       ← Runs all bronze jobs in parallel
│   ├── workflow_gold         ← Runs gold jobs in computed dependency waves
│   └── workflow_ml           ← Training then inference
│
└── jobs/
    ├── bronze/               ← 10001.json … 10009.json
    ├── silver/               ← 20001.json … 20009.json
    ├── gold/                 ← 30001.json … 30009.json
    └── ml/                   ← 50001.json … 30005.json
```

### ETL Notebook Design

All three ETL notebooks follow the same parameterized pattern — they receive a single `job_parameters` JSON widget:

```python
parameters   = json.loads(dbutils.widgets.get("job_parameters"))
catalog      = parameters.get("catalog")
source_view  = catalog + "." + parameters.get("source_view")
target_table = catalog + "." + parameters.get("target_table")
primary_keys = parameters.get("primary_keys")
```

One notebook handles all jobs of the same type — no per-table notebooks. The `ETL_NB` field in each job JSON specifies which ETL notebook to call, and `trigger_jobs` in bronze configs tells the ETL notebook to fire Silver jobs automatically at completion.

---

## 6. Data Architecture — Medallion Layers

### Bronze Layer — Raw Delta Tables

Raw data is ingested from the Unity Catalog Volume into Bronze Delta tables with schema enforcement and deduplication. Each Bronze job config contains a `trigger_jobs` field — the ETL notebook fires the corresponding Silver job automatically at the end of the Bronze run.

```json
{
  "job_id": 10001,
  "ETL_NB": "ETL/raw_to_bronze",
  "target_table": "bronze.sellers",
  "location": "/Volumes/ecommerce/bronze/data_file_container",
  "trigger_jobs": [{"job_id": 20001, "job_type": "silver"}]
}
```

**Bronze DDL tables (10 tables):**

| Job | Table |
|---|---|
| 10001 | `bronze.sellers` |
| 10002 | `bronze.order_payments` |
| 10003 | `bronze.order_items` |
| 10004 | `bronze.geolocation` |
| 10005 | `bronze.customers` |
| 10006 | `bronze.product_category_name_translation` |
| 10007 | `bronze.products` |
| 10008 | `bronze.order_reviews` |
| 10009 | `bronze.orders` |

**Bronze views (9 views):** After ingestion, Bronze views (`vw_sellers`, `vw_customers`, etc.) expose the raw Delta data to the Silver cleaning layer. These are defined in `DDL/view/bronze/`.

### Silver Layer — Views + Delta Tables

The Silver layer has two components:

**1. Cleaning views (`vw_cln_ltst_*`)** — defined in `DDL/view/silver/`:
Apply deduplication, type casting, null handling, and latest-record filtering on top of Bronze tables. These views are always live — no pipeline needed.

**2. Enriched views** — also defined in `DDL/view/silver/`:
Join multiple cleaned views together and compute derived columns (delivery delays, sentiment flags, revenue metrics, payment pivots). These power the Gold ETL jobs.

| Silver View | Grain | Key Logic |
|---|---|---|
| `vw_cln_ltst_orders` | order_id | Dedup, cast timestamps, latest record per order |
| `vw_cln_ltst_customers` | customer_id | Dedup, standardise city/state |
| `vw_orders_enriched` | order_id | Joins orders + customers + geolocation, delivery delay flags |
| `vw_order_items_enriched` | order_id + item_id | Joins items + products + sellers, revenue metrics |
| `vw_payments_agg` | order_id | Pivots payment types, installment flags |
| `vw_enriched_reviews` | order_id | Sentiment flags, review lag, low-score indicators |
| `vw_customer_order_history` | customer_unique_id | All orders aggregated per real customer |

**3. Silver Delta tables (via Gold jobs using SCD Type 1):**
The Silver enriched views are materialised into Silver Delta tables using SCD Type 1 upsert. These are run as **Gold-type jobs** (`ETL/scd_type_1`) with the Silver view as the source:

| Job | Source View | Target Delta Table |
|---|---|---|
| 20001 | `bronze.vw_sellers` | `silver.sellers` |
| 20002 | `bronze.vw_order_payments` | `silver.order_payments` |
| 20003 | `bronze.vw_order_items` | `silver.order_items` |
| 20004 | `bronze.vw_geolocation` | `silver.geolocation` |
| 20005 | `bronze.vw_customers` | `silver.customers` |
| 20006 | `bronze.vw_product_category_name_translation` | `silver.product_category_name_translation` |
| 20007 | `bronze.vw_products` | `silver.products` |
| 20008 | `bronze.vw_order_reviews` | `silver.order_reviews` |
| 20009 | `bronze.vw_orders` | `silver.orders` |

### Gold Layer — Delta Tables + Analytics Views

Gold Delta tables are materialised from Silver enriched views using **SCD Type 1** (`ETL/scd_type_1`). The Gold job JSON specifies `dependent_jobs` which the orchestrator uses to compute execution waves automatically.

```json
{
  "job_id": 30001,
  "ETL_NB": "ETL/scd_type_1",
  "source_view": "silver.vw_orders_enriched",
  "target_table": "gold.orders_enriched",
  "dependent_jobs": [
    {"job_id": 20005, "job_type": "silver"},
    {"job_id": 20009, "job_type": "silver"}
  ]
}
```

**Gold ETL jobs (9 jobs):**

| Job | Source View | Target Table | Consumer |
|---|---|---|---|
| 30001 | `silver.vw_orders_enriched` | `gold.orders_enriched` | Analytics, downstream gold |
| 30002 | `silver.vw_order_items_enriched` | `gold.order_items_enriched` | Analytics, product features |
| 30003 | `silver.vw_payments_agg` | `gold.payments_agg` | Analytics, customer history |
| 30004 | `silver.vw_enriched_reviews` | `gold.enriched_reviews` | Analytics, customer history |
| 30005 | `silver.vw_customer_order_history` | `gold.customer_order_history` | Customer features |
| 30006 | `gold.vw_customer_features` | `gold.customer_features` | All ML models |
| 30007 | `gold.vw_product_features` | `gold.product_features` | Recommendation model |
| 30008 | `gold.vw_business_kpis` | `gold.business_kpis` | BI / Dashboards |
| 30009 | `gold.vw_cohort_analysis` | `gold.cohort_analysis` | Analytics, Finance |

**Gold analytics views** (defined in `DDL/view/gold/`) sit on top of Gold Delta tables and are consumed directly by ML training notebooks and dashboards:

| View | Purpose |
|---|---|
| `vw_customer_features` | 25 RFM + behavioural features, ML targets — source for all ML jobs |
| `vw_customer_360` | Joins all prediction tables — foundation for all dashboards |
| `vw_business_kpis` | Monthly aggregated revenue, delivery, review KPIs |
| `vw_cohort_analysis` | Monthly retention matrix by acquisition cohort |
| `vw_product_features` | Category-level sales velocity and review metrics |

#### Delta Lake Features Used

| Feature | Where Applied |
|---|---|
| Schema enforcement | Bronze ingestion — rejects invalid data at write time |
| ACID transactions | SCD Type 1 MERGE upserts in all Silver and Gold Delta tables |
| Time Travel | Inference comparison — current vs prior predictions |
| OPTIMIZE + ZORDER | All Gold tables ZORDERed by primary key |
| Auto-optimize | Enabled on all Gold tables via TBLPROPERTIES |
| SCD Type 1 MERGE | Standard ETL pattern for Silver and Gold materialisation |

---

## 7. Machine Learning Models

All ML notebooks are **fully parameterized** — the same notebook trains any compatible dataset by passing a different JSON configuration via the `job_parameters` widget.

### ML Job Map

| Job | Type | Source | Target | Notebook |
|---|---|---|---|---|
| 40001 | Training | `gold.vw_customer_features` | `gold.churn_predictions` | `ML/XGBoost` |
| 50002 | Training | `gold.vw_customer_features` | `gold.clv_predictions` | `ML/CLV_regression` |
| 50004 | Inference | `gold.model_registry` | `gold.churn_predictions` | `ML/batch_inference` |
| 50003 | Inference | `gold.model_registry` | `gold.clv_predictions` | `ML/batch_inference` |
| 50005 | Training | `gold.vw_customer_features` | `gold.customer_segments` | `ML/K_means_clustering` |

### Model 1 — Churn Prediction (XGBoost Classifier)

**Business question:** Which customers are at risk of not purchasing again?

| Item | Detail |
|---|---|
| Algorithm | XGBoost with `scale_pos_weight` for class imbalance |
| Target | `churn_label` (binary 0/1) |
| Training rows | 44,034 (52,062 recently acquired excluded — no prediction window) |
| Class split | 64.5% not churned / 35.5% churned |
| Features | 25 (RFM scores, behavioural, payment, tenure) |
| AUC-ROC | **0.7323** |
| F1 Score | **0.5839** (at best threshold 0.45) |
| Best threshold | 0.45 (tuned via F1 maximisation) |
| Output | `gold.churn_predictions` — probability + risk tier per customer |

**Leakage prevention:** `recency_days`, `is_inactive_90d`, `R_score`, and `RFM_score` are excluded from features — they are direct inputs to the churn label formula.

### Model 2 — CLV Regression (XGBoost + Random Forest)

**Business question:** How much revenue will each customer generate in the next 90 days?

| Item | Detail |
|---|---|
| Algorithms | XGBoost Regressor vs Random Forest Regressor |
| Target | `clv_next_90d_estimate` (BRL) |
| Target treatment | Capped at 500 BRL + `log1p` transform to fix right-skew |
| Training rows | 96,064 |
| Split strategy | Stratified by decile bins — ensures balanced CLV distribution |
| Best model | XGBoost Regressor |
| R² | **0.7756** (original BRL scale after inverse transform) |
| RMSE | **15.20 BRL** |
| MAE | **1.19 BRL** |
| Output | `gold.clv_predictions` — predicted BRL value + CLV tier per customer |

**Key challenge resolved:** Initial R² was **-2.25** due to extreme outliers (max = 419,031 BRL). Fixed with outlier capping, log transformation, and stratified splitting.

### Model 3 — Customer Segmentation (K-Means)

**Business question:** What distinct customer behavioural groups exist?

| Item | Detail |
|---|---|
| Algorithm | K-Means with StandardScaler |
| Feature groups | RFM + Behavioural + Tenure (17 features) |
| K selection | Elbow + Silhouette evaluated for k=3 to k=10 |
| Optimal k | **3** (Silhouette = 0.3594) |
| Output | `gold.customer_segments` — cluster label + segment name per customer |

**Discovered Segments:**

| Segment | Size | Profile | Business Action |
|---|---|---|---|
| Standard Buyers | 76,934 (80.1%) | Single purchase, avg 135 BRL, satisfied (4.58 review) | Second-purchase campaigns |
| Loyal Champions | 2,154 (2.2%) | Multi-order (avg 2.4x), 350 BRL spend, 120 days tenure | VIP rewards, loyalty programme |
| Dissatisfied High Spenders | 17,008 (17.7%) | High order value (285 BRL), terrible reviews (1.65), 30% late delivery | Service recovery, logistics review |

### Why Product Recommendations Were Skipped

ALS Collaborative Filtering was evaluated and deliberately excluded. With 97% of customers placing exactly one order in one category, the user-item interaction matrix is essentially an identity matrix — ALS has no cross-customer preference signal to learn from. Forcing it would produce meaningless recommendations. The correct production approach (ALS for repeat buyers + popularity fallback for single-order buyers) falls outside the scope of this dataset.

### MLflow Experiment Structure

```
/Users/sahil.prusty09@gmail.com/experiments/
├── ecommerce_churn_prediction/
│   ├── xgboost_baseline_40001   AUC=0.7254
│   └── xgboost_tuned_40001      AUC=0.7323 ✅ production
├── ecommerce_clv_regression/
│   ├── clv_random_forest_50002  R²=0.7742
│   └── clv_xgboost_50002        R²=0.7756 ✅ production
├── ecommerce_segmentation/
│   └── kmeans_k3_50005          Silhouette=0.3594 ✅ production
└── ecommerce_inference/
    └── inference run per day    tracks scored counts + distributions
```

All production model metadata (run_id, model_uri, feature_cols, best_threshold) is persisted in `gold.model_registry` — a Delta table that acts as the handoff between training and inference.

---

## 8. Batch Inference Pipelines

A **single generic inference notebook** (`ML/batch_inference`) handles both classification (churn) and regression (CLV) by reading all model config from `gold.model_registry` at runtime.

```python
# Inference reads everything from the registry — no hardcoded values
registry_row   = spark.table("gold.model_registry").filter(...)
model_uri      = registry_row["model_uri"]
feature_cols   = json.loads(registry_row["feature_cols"])
best_threshold = registry_row["best_threshold"]
score_col      = registry_row["score_col"]
```

Retraining automatically propagates to inference — update the model, the registry updates, and the next inference run picks it up without any code changes.

### Inference Outputs

**`gold.churn_predictions`** — scored daily for all 96K customers:

| Column | Example | Description |
|---|---|---|
| `customer_unique_id` | `abc123...` | Primary key |
| `churn_probability` | `0.73` | Model score |
| `churn_label_predicted` | `1` | Binary label at threshold 0.45 |
| `risk_tier` | `High` | High ≥ 0.70 / Medium 0.45–0.70 / Low < 0.45 |
| `model_version` | `3` | MLflow model version |
| `prediction_date` | `2026-03-15` | Date of inference run |

**`gold.clv_predictions`** — scored daily for all 96K customers:

| Column | Example | Description |
|---|---|---|
| `predicted_clv_90d` | `45.20` | Predicted BRL revenue in next 90 days |
| `clv_tier` | `High Value` | High ≥ 50 BRL / Medium 15–50 / Low < 15 |

**`gold.customer_segments`** — refreshed per segmentation run:

| Column | Example | Description |
|---|---|---|
| `cluster_id` | `1` | K-Means cluster number |
| `segment_name` | `Loyal Champions` | Human-readable segment label |
| `centroid_distance` | `2.3141` | Distance from cluster centre |

### Output Validation

Every inference run performs 5 automated sanity checks:

```
✅ Check 1 — Row count matches scored input (96,096)
✅ Check 2 — Zero null scores
✅ Check 3 — Classification: probabilities in [0,1] | Regression: values >= 0
✅ Check 4 — All 3 tiers present
✅ Check 5 — High risk tier < 50% of total
```

---

## 9. Analytics & Dashboards

### Foundation View — `gold.vw_customer_360`

All 5 dashboards are powered by a single view (`DDL/view/dashboards/vw_customer_360.sql`) that joins all prediction tables:

```sql
SELECT
    cf.*,
    cp.churn_probability,
    cp.risk_tier,
    clv.predicted_clv_90d,
    clv.clv_tier,
    cs.segment_name,
    ROUND(cp.churn_probability * clv.predicted_clv_90d, 2) AS revenue_at_risk_90d
FROM gold.vw_customer_features   cf
LEFT JOIN gold.churn_predictions  cp  ON cf.customer_unique_id = cp.customer_unique_id
LEFT JOIN gold.clv_predictions    clv ON cf.customer_unique_id = clv.customer_unique_id
LEFT JOIN gold.customer_segments  cs  ON cf.customer_unique_id = cs.customer_unique_id
```

### Dashboard Pages

| Dashboard | Key Insights |
|---|---|
| **Business KPIs** | Revenue trend (MoM growth), late delivery rate by state, review score trend, payment mix |
| **Churn Analysis** | 8,771 High risk customers (9.1%), risk tier breakdown, churn by RFM segment and state |
| **CLV Analysis** | 5,968 High Value customers (6.2%), total predicted CLV by state, CLV × Churn risk matrix |
| **Customer Segments** | 3 segments profiled, segment × CLV tier cross, state-level distribution |
| **Customer 360** | Actionable priority cohorts, total revenue at risk, cohort retention heatmap |

**Most actionable query — Priority Cohorts:**

```sql
CASE
    WHEN risk_tier = 'High' AND clv_tier = 'High Value'   THEN 'URGENT — Retain Now'
    WHEN risk_tier = 'High' AND clv_tier = 'Medium Value' THEN 'High Priority — Win Back'
    WHEN risk_tier = 'Low'  AND clv_tier = 'High Value'   THEN 'Nurture — VIP Program'
END AS action_priority
```

---

## 10. Orchestration

Three separate workflows chained by the master pipeline orchestrator. Silver jobs are triggered internally by the Bronze ETL notebook via `trigger_jobs` in each bronze job config — they are not separately orchestrated.

```
run_pipeline.ipynb
      │
      ├── workflow_bronze.ipynb
      │       └── Discovers all JSONs from jobs/bronze/
      │           Reads ETL_NB path from each config
      │           Runs all bronze jobs in parallel
      │           Silver triggered inside ETL notebook via trigger_jobs
      │
      ├── workflow_gold.ipynb
      │       └── Loads all JSONs from jobs/gold/
      │           Reads dependent_jobs from each config
      │           Topological sort → computes execution waves automatically
      │           Runs each wave in parallel
      │
      └── workflow_ml.ipynb
              └── Phase 1: Train churn + CLV + K-Means (parallel)
                  Resolve model names from gold.model_registry
                  Phase 2: Run churn + CLV inference (parallel)
```

### Dynamic Dependency Resolution

Gold wave computation uses topological sorting — no hardcoded wave assignments. Adding a new gold table requires only adding a new JSON file:

```python
# Reads dependent_jobs from each gold JSON, computes waves:
# Wave 1 → jobs with no gold dependencies
# Wave 2 → jobs depending on Wave 1 completions
# Wave N → further levels as needed
while remaining:
    wave = {jid for jid in remaining if gold_deps[jid].issubset(assigned)}
    waves.append(wave)
    assigned  |= wave
    remaining -= wave
```

---

## 11. Key Results

| Metric | Value |
|---|---|
| Total customers scored daily | 96,096 |
| Churn model AUC-ROC | 0.7323 |
| CLV model R² | 0.7756 |
| CLV model RMSE | 15.20 BRL |
| Segmentation silhouette score | 0.3594 |
| High churn risk customers | 8,771 (9.1%) |
| High CLV customers | 5,968 (6.2%) |
| Bronze Delta tables | 9 |
| Silver Delta tables | 9 (via SCD Type 1) |
| Gold Delta tables | 9 |
| SQL Views (Bronze + Silver + Gold) | 65 |
| MLflow experiments | 4 |
| Dashboard pages | 5 (31 widgets, 21 datasets) |

---

## 12. How to Run

### Prerequisites

- Databricks workspace (Community Edition or above)
- Kaggle account + API token
- Unity Catalog enabled with catalog `ecommerce` created

### Step 1 — Catalog & Schema Setup

```sql
CREATE CATALOG IF NOT EXISTS ecommerce;
CREATE SCHEMA IF NOT EXISTS ecommerce.bronze;
CREATE SCHEMA IF NOT EXISTS ecommerce.silver;
CREATE SCHEMA IF NOT EXISTS ecommerce.gold;
CREATE VOLUME IF NOT EXISTS ecommerce.bronze.data_file_container;
```

### Step 2 — Run All DDL

Run all SQL files from `DDL/` in order:

```
1. DDL/table/bronze/*.sql      → Create Bronze Delta tables
2. DDL/table/silver/*.sql      → Create Silver Delta tables
3. DDL/table/gold/*.sql        → Create Gold Delta tables
4. DDL/view/bronze/*.sql       → Create Bronze views
5. DDL/view/silver/*.sql       → Create Silver cleaning + enriched views
6. DDL/view/gold/*.sql         → Create Gold analytics views
7. DDL/view/dashboards/*.sql   → Create Customer 360 dashboard view
```

### Step 3 — Download Data

Run `00_kaggle_dataset_download.py` with your Kaggle credentials to download all 9 CSV files into the Unity Catalog Volume.

### Step 4 — Run the Pipeline

Import the 4 orchestration notebooks and trigger the master:

```
orchestration/run_pipeline  →  Runs all 3 workflows end-to-end
```

Or run individual workflows:

```
orchestration/workflow_bronze  →  Bronze ingestion + Silver triggered internally
orchestration/workflow_gold    →  Gold materialization via SCD Type 1
orchestration/workflow_ml      →  Model training + batch inference
```

### Step 5 — Import Dashboard

Import `ecommerce_dashboard.lvdash.json` via:

```
Databricks → Dashboards → New Dashboard → Import from file
```

---

## 13. Design Decisions

**Why SCD Type 1 for Silver and Gold materialisation?**
All source data in this project represents current state — orders don't retroactively change their status in a way that requires historical tracking. SCD Type 1 (upsert by primary key) is the correct and simplest pattern: new records are inserted, changed records are updated, and deleted records are removed. This keeps Gold tables clean and compact without accumulating historical versions that would require SCD Type 2.

**Why separate Bronze views from Bronze tables?**
Bronze tables hold raw immutable data. Bronze views (`vw_sellers`, `vw_orders`, etc.) apply a consistent interface layer for Silver consumption — column aliasing, type normalisation, and any Bronze-level business rules. This decouples the physical storage schema from the logical consumption schema, making it easy to change Bronze table structure without rewriting Silver ETL.

**Why trigger Silver inside the Bronze ETL notebook?**
Rather than orchestrating Bronze and Silver as independent parallel layers, each Bronze job immediately triggers its Silver counterpart via `trigger_jobs` in the config. This creates a natural pipeline where raw data is cleaned and structured as soon as it lands, reducing end-to-end latency and keeping the orchestrator simple — it only schedules Bronze and the Silver jobs follow automatically.

**Why exclude recently acquired customers from churn training?**
Customers acquired after January 2018 had fewer than 90 days before the dataset ended (August 2018) — not enough time to establish whether they returned or churned. Including them would inflate the churn rate to 71% and make the model trivially easy. Their `churn_label` is set to NULL and they are excluded from training but included in inference — the model can still score them.

**Why log-transform the CLV target?**
CLV follows a heavily right-skewed distribution (median = 10.89 BRL, max = 419,031 BRL). Training on raw values caused tree models to overfit extreme outliers (R² = -2.25). Log transformation normalised the distribution and both models achieved R² > 0.77 on the original BRL scale after inverse transformation.

**Why skip ALS product recommendations?**
With 97% single-order customers, the user-category interaction matrix is near-diagonal — almost no shared preferences to learn. ALS requires multiple interactions per user to find latent preference factors. Forcing it would produce random recommendations. The decision was documented transparently rather than producing meaningless output.

**Why use a generic inference notebook?**
A single inference notebook parameterised by `prediction_type` eliminates code duplication, ensures consistent validation logic, and makes it trivial to add new models — just register a new entry in `gold.model_registry` and point it at the same notebook.

---

*Built on Databricks Community Edition · Delta Lake · Apache Spark · MLflow · XGBoost · scikit-learn*
