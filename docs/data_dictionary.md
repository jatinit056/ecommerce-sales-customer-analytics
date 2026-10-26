# Data dictionary

## Raw tables (`data/raw/`)

| File | Rows | Grain | Key columns |
|---|---|---|---|
| olist_orders_dataset.csv | 99,441 | one row per order | order_id, customer_id, order_status, 5 timestamps |
| olist_customers_dataset.csv | 99,441 | one row per order-customer id | customer_id, **customer_unique_id** (96,096 real customers), zip, city, state |
| olist_order_items_dataset.csv | 112,650 | one row per item | order_id, order_item_id, product_id, seller_id, price, freight_value |
| olist_order_payments_dataset.csv | 103,886 | one row per payment | order_id, payment_sequential, payment_type, installments, value |
| olist_order_reviews_dataset.csv | 100,000 | one row per review | review_id, order_id, review_score, comments, dates |
| olist_products_dataset.csv | 32,951 | one row per product | product_id, category (Portuguese), size/weight |
| olist_sellers_dataset.csv | 3,095 | one row per seller | seller_id, zip, city, state |
| product_category_name_translation.csv | 71 | one row per category | Portuguese → English name |

## Cleaned tables (`data/cleaned/`) — created by the notebook

### fact_orders.csv — one row per order (all 99,441 orders, with flags)
| Column | Description | Data Type | Example | Business Meaning |
|---|---|---|---|---|
| `order_id` | Unique order identifier | text | e481f51cbd… | Primary key; one row per order |
| `customer_unique_id` | Identifier of the real customer | text | 7c396fd483… | Used to count unique and repeat customers |
| `customer_state` | Customer's Brazilian state (2 letters) | text | SP | Regional analysis |
| `customer_region` | IBGE macro-region of the state | text | Southeast | Regional roll-up (North, Northeast, Center-West, Southeast, South) |
| `customer_city` | Customer city (lower case) | text | sao paulo | City-level drill-down |
| `order_status` | Order status at the time of extraction | text | delivered | Only 'delivered' orders count as revenue |
| `is_delivered` | order_status = delivered | boolean | True | Revenue filter |
| `is_canceled` | order_status in (canceled, unavailable) | boolean | False | Cancellation rate |
| `in_analysis_window` | Purchased 2017-01-01 to 2018-08-31 | boolean | True | Excludes incomplete months at both ends |
| `order_purchase_timestamp` | Date and time the order was placed | datetime | 2017-10-02 10:56:33 | Time-of-day and trend analysis |
| `purchase_date` | Purchase date (no time) | date | 2017-10-02 | Join key to a date table |
| `year_month` | Purchase month (YYYY-MM) | text | 2017-10 | Monthly trend |
| `purchase_year` | Purchase year | integer | 2017 | Year-over-year comparison |
| `purchase_weekday` | Weekday name | text | Monday | Weekly demand pattern |
| `purchase_hour` | Hour of day (0–23) | integer | 10 | Intraday demand pattern |
| `items_count` | Number of items in the order | integer | 1 | Basket size |
| `product_revenue` | Sum of item prices (R$) | decimal | 29.99 | Merchandise value |
| `freight_value` | Sum of freight charged (R$) | decimal | 8.72 | Shipping cost paid by the customer |
| `order_revenue` | product_revenue + freight_value (R$) | decimal | 38.71 | Main revenue measure |
| `main_category` | Category of the most expensive item | text | Housewares | Order-level category |
| `primary_payment_type` | Payment method that paid the largest amount | text | voucher | Payment mix |
| `max_installments` | Highest number of installments in the order | integer | 1 | Credit behaviour |
| `review_score` | 1–5 review score (latest review) | integer | 4 | Customer satisfaction |
| `delivery_days` | Days from purchase to delivery | decimal | 8.44 | Logistics speed (delivered orders only) |
| `delay_days` | Delivery date minus estimated date (days) | decimal | -8.0 | Positive = late |
| `is_late` | delay_days > 0 | boolean (blank if not delivered) | False | On-time delivery KPI |
| `dq_issue` | Data-quality flag (blank = no issue) | text | carrier_da… | Rows kept but flagged for transparency |

### fact_order_items.csv — one row per item sold (112,650 items)
| Column | Description | Data Type | Example | Business Meaning |
|---|---|---|---|---|
| `order_id` | Order identifier | text | 00010242fe… | Foreign key to fact_orders |
| `order_item_id` | Item number inside the order (1, 2, 3…) | integer | 1 | Part of the primary key |
| `product_id` | Product identifier (anonymised) | text | 4244733e06… | Product-level analysis |
| `seller_id` | Seller identifier (anonymised) | text | 48436dade1… | Seller concentration |
| `category` | English product category (cleaned) | text | Cool stuff | Category performance |
| `seller_state` | Seller's state | text | SP | Where supply comes from |
| `customer_state` | Customer's state | text | RJ | Where demand comes from |
| `purchase_date` | Order purchase date | date | 2017-09-13 | Trend analysis |
| `year_month` | Purchase month | text | 2017-09 | Monthly trend |
| `order_status` | Status of the parent order | text | delivered | Revenue filter |
| `is_delivered` | Parent order delivered | boolean | True | Revenue filter |
| `in_analysis_window` | Parent order purchased in the window | boolean | True | Scope filter |
| `price` | Item price (R$) | decimal | 58.9 | Merchandise value |
| `freight_value` | Freight for this item (R$) | decimal | 13.29 | Shipping cost |
| `item_revenue` | price + freight_value (R$) | decimal | 72.19 | Revenue at item level |

### dim_customers.csv — one row per real customer with a delivered order in the window (93,104 customers)
| Column | Description | Data Type | Example | Business Meaning |
|---|---|---|---|---|
| `customer_unique_id` | Real customer identifier | text | 0000366f3b… | Primary key |
| `customer_state` | State of the latest order | text | SP | Regional segmentation |
| `customer_city` | City of the latest order | text | cajamar | Local segmentation |
| `first_purchase_date` | First delivered order date | date | 2018-05-10 | Customer age |
| `last_purchase_date` | Latest delivered order date | date | 2018-05-10 | Recency |
| `orders_count` | Delivered orders in the window | integer | 1 | Frequency |
| `total_revenue` | Total spend (R$) | decimal | 141.9 | Monetary value |
| `avg_order_value` | total_revenue / orders_count | decimal | 141.9 | Typical basket |
| `recency_days` | Days from last order to 2018-09-01 | integer | 114 | How recently the customer bought |
| `is_repeat_customer` | orders_count ≥ 2 | boolean | False | Repeat-purchase KPI |
| `r_score` | Recency quartile score (4 = most recent) | integer | 4 | RFM scoring |
| `m_score` | Spend quartile score (4 = top 25%) | integer | 3 | RFM scoring |
| `segment` | RFM-style segment | text | Regular recent | Targeting: Repeat, High-value recent/lapsed, Regular recent/lapsed |

### dim_state.csv — reference table (27 states)
| Column | Description | Data Type | Example | Business Meaning |
|---|---|---|---|---|
| `state_code` | 2-letter state code | text | AC | Primary key; joins to customer_state |
| `state_name` | Full state name | text | Acre | Labels and map |
| `region` | IBGE macro-region | text | North | Regional roll-up |
| `map_location` | '<State name>, Brazil' | text | Acre, Brazil | Helps Power BI place the state on a map |

`dim_state` is **reference data added by the analyst** (official IBGE macro-regions of Brazil), not part of the Olist
dataset.
