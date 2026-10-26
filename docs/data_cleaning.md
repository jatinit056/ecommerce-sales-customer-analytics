# Data cleaning

All cleaning is done in `notebooks/ecommerce_sales_customer_analysis.ipynb` (sections 8–12). The raw files in
`data/raw/` are never modified; the notebook writes new files to `data/cleaned/`. Every step is logged with the number
of rows affected in `reports/cleaning_log.csv`, and the data-quality checks are saved in `reports/data_quality_checks.csv`.
The same rules are implemented in SQL in `sql/cleaning_views.sql`, and `scripts/reconcile_sql_python.py` proves that both
give the same KPIs (26/26 checks pass).

## 1. Missing values

| Table.column | Missing | Decision |
|---|---|---|
| orders.order_approved_at | 160 | Kept. Not used in any KPI. |
| orders.order_delivered_carrier_date | 1,783 | Kept. Missing mostly for orders that never shipped. |
| orders.order_delivered_customer_date | 2,965 | Kept. 2,957 belong to orders that were never delivered (expected). **8 orders have status "delivered" but no date** — they count as revenue but are left out of delivery-time metrics. |
| reviews.review_comment_title / message | 88,285 / 58,247 | Kept as-is. Comments are optional; only the 1–5 score is analysed (text columns dropped from the cleaned output). |
| products.product_category_name | 610 | Filled with **"Unknown"** instead of dropping, because these products generated real revenue. |
| products size/weight columns | 2 | Kept; not used. |

## 2. Duplicate records

* No table has fully duplicated rows, and every primary key (order_id, customer_id, product_id, seller_id,
  order_id + order_item_id) is unique.
* **Reviews:** 555 orders have more than one review and 827 review_ids are shared by several orders. To get one score
  per order, the **latest answered review** is kept (sort by answer timestamp, creation date, review_id → keep last):
  100,000 → 99,441 rows (559 removed).
* **Customers:** `customer_id` is created per order, so one person can have several ids. The real customer is
  `customer_unique_id` (96,096 people vs 99,441 ids). All customer
  KPIs use `customer_unique_id`; using `customer_id` would hide every repeat purchase.

## 3. Invalid values

| Issue | Rows | Decision |
|---|---|---|
| payment_installments = 0 | 2 | Impossible value → set to 1 (single payment). |
| payment_type = "not_defined" (value R$0) | 3 | Kept as its own label; they do not affect revenue. |
| payment_value = 0 | 9 (6 voucher, 3 not_defined) | Kept — zero-value vouchers / undefined payments do not change revenue. |
| freight_value = 0 | 383 items | Kept — free shipping is valid. |
| Carrier pickup before purchase | 166 orders | Flagged in `dq_issue`, kept. Mostly minutes apart (clock errors); carrier date is not used in KPIs. |
| Delivered to customer before carrier pickup | 23 orders | Flagged, kept. Delivery time is measured purchase → customer, so not affected. |
| Canceled orders with a delivery date | 6 orders | Flagged, kept. Revenue follows the status (not counted). |
| Orders with no items | 775 orders | Kept with revenue 0. Almost all are `unavailable` or `canceled`. |
| Order with no payment record | 1 order | Kept. Revenue is based on items, which exist for this order. |

In total 203 orders carry a `dq_issue` flag; none were deleted.

## 4. Date conversion

* The 5 order timestamps, `shipping_limit_date` and the review dates arrive as text and are converted to `datetime`.
* Derived date parts: purchase date, year-month, year, weekday, hour.
* **Analysis window: 2017-01-01 to 2018-08-31.** Sep–Dec 2016 has very few orders (none in Nov 2016) and Sep–Oct 2018
  only has a handful of mostly canceled orders. 349 orders fall outside the window — they stay in
  `fact_orders.csv` with `in_analysis_window = False` but are excluded from KPIs.

## 5. Data-type conversion

* Zip-code prefixes are read as **text** so leading zeros are kept (e.g. `01037`, not `1037`).
* Money columns stay as decimals and are rounded to 2 decimals in the cleaned files.
* In SQL, money is stored as `NUMERIC(10,2)` (exact decimal) and timestamps as `TIMESTAMP` (`sql/schema.sql`).

## 6. Outliers

Order values are right-skewed (median R$105.28, mean R$159.79). The IQR rule
flags 7,551 orders above R$347.80. They are **kept**: they are genuine purchases of
expensive items (computers, furniture, watches), and removing them would understate revenue. The median is reported next
to the mean where the skew matters.

## 7. Standardisation

| What | Rows | Decision |
|---|---|---|
| Misspelled column names in products (`product_name_lenght`…) | — | Renamed to `…_length` in the cleaned data (kept original names in SQL so the raw CSV loads unchanged). |
| Categories without an English name | 2 | Added: `pc_gamer` → "Pc gamer", `portateis_cozinha_e_preparadores_de_alimentos` → "Portable kitchen food preparers". |
| Misspelled English category names | 4 | `fashio_female_clothing`, `costruction_tools_*`, `home_confort` corrected. |
| Category display format | all | `bed_bath_table` → "Bed bath table". |
| Seller city spellings | 25 sellers | Accents removed, "/state" suffixes and numbers-as-city removed (e.g. `sbc/sp` → `sbc`, `são paulo` → `sao paulo`). 611 → 589 distinct cities. |

## 8. Derived columns

| Column | Formula |
|---|---|
| order_revenue | sum(price) + sum(freight_value) per order |
| main_category | category of the most expensive item (ties → lowest item number); only 0.8% of orders mix categories |
| primary_payment_type | method that paid the largest amount (ties → first payment) |
| delivery_days | (delivered timestamp − purchase timestamp) in days |
| delay_days, is_late | delivery date − estimated date; late if > 0 |
| customer_region | state → IBGE region (reference table) |
| RFM fields | recency, frequency, monetary; quartile scores; 5 segments |

## 9. Assumptions

1. **Revenue = price + freight** (what the customer paid). Payments reconcile with this for 99.61% of
   orders; small differences come from vouchers and installment interest.
2. **Only delivered orders count as revenue**; canceled/unavailable orders are used for the cancellation rate.
3. **Profit cannot be calculated** — the dataset has no product cost, commission or marketing spend.
4. The latest review is the customer's final opinion of the order.
5. A "repeat customer" has 2+ delivered orders in the window. 827 of the 2,789 repeat
   customers (29.7%) placed their second order on the **same day** (often a split checkout), so true
   "came back later" repeat behaviour is even lower — see SQL query Q21.
