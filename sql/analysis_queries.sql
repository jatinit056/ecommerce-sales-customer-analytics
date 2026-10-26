/* =====================================================================
   E-commerce Sales & Customer Analytics (Olist) - analysis queries
   Database : PostgreSQL 13+ (tested on PostgreSQL 16)
   Requires : schema.sql -> load_data.sql -> cleaning_views.sql
   Run      : psql -d olist_db -f sql/analysis_queries.sql
   Scope    : unless stated otherwise, KPIs use DELIVERED orders purchased
              between 2017-01-01 and 2018-08-31 (view v_delivered_orders).
   The business question behind every query is listed in
   sql/business_questions.md. Saved outputs are in sql/results/.
   ===================================================================== */

SET search_path TO olist;

------------------------------------------------------------------------
-- LEVEL 1 - BASICS (SELECT, WHERE, GROUP BY, ORDER BY, aggregates)
------------------------------------------------------------------------

-- Q01: How are all orders split by status?
SELECT order_status,
       COUNT(*)                                            AS orders,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS pct_of_orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- Q02: Headline KPIs - delivered orders, revenue, AOV, customers
SELECT COUNT(*)                                        AS delivered_orders,
       SUM(order_revenue)                              AS total_revenue,
       SUM(product_revenue)                            AS product_revenue,
       SUM(freight_value)                              AS freight_revenue,
       ROUND(AVG(order_revenue), 2)                    AS avg_order_value,
       COUNT(DISTINCT customer_unique_id)              AS unique_customers,
       ROUND(SUM(order_revenue) / COUNT(DISTINCT customer_unique_id), 2) AS revenue_per_customer,
       ROUND(AVG(items_count), 2)                      AS avg_items_per_order,
       ROUND(100.0 * SUM(freight_value) / SUM(order_revenue), 2) AS freight_share_pct,
       ROUND(AVG(review_score), 2)                     AS avg_review_score
FROM v_delivered_orders;

-- Q03: Which payment methods do customers use, and how much do they pay?
SELECT payment_type,
       COUNT(DISTINCT order_id)                 AS orders,
       SUM(payment_value)                       AS amount_paid,
       ROUND(AVG(payment_value), 2)             AS avg_payment,
       ROUND(AVG(payment_installments), 2)      AS avg_installments
FROM order_payments
WHERE payment_value > 0
GROUP BY payment_type
ORDER BY amount_paid DESC;

-- Q04: Which 10 customer states generate the most revenue? (INNER JOIN)
SELECT c.customer_state,
       COUNT(DISTINCT o.order_id)               AS orders,
       SUM(i.price + i.freight_value)           AS revenue,
       ROUND(SUM(i.price + i.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
INNER JOIN customers c   ON c.customer_id = o.customer_id
INNER JOIN order_items i ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 10;

-- Q05: What does the monthly revenue and order trend look like? (date functions)
SELECT TO_CHAR(purchase_month, 'YYYY-MM')       AS month,
       COUNT(*)                                 AS orders,
       SUM(order_revenue)                       AS revenue,
       ROUND(AVG(order_revenue), 2)             AS avg_order_value,
       COUNT(DISTINCT customer_unique_id)       AS customers
FROM v_delivered_orders
GROUP BY purchase_month
ORDER BY purchase_month;

-- Q06: How are orders distributed across order-value bands? (CASE WHEN)
SELECT CASE
           WHEN order_revenue <  50  THEN '1. Under R$50'
           WHEN order_revenue < 100  THEN '2. R$50-99'
           WHEN order_revenue < 200  THEN '3. R$100-199'
           WHEN order_revenue < 500  THEN '4. R$200-499'
           ELSE                           '5. R$500+'
       END                                                         AS order_value_band,
       COUNT(*)                                                    AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)          AS pct_of_orders,
       SUM(order_revenue)                                          AS revenue,
       ROUND(100.0 * SUM(order_revenue) / SUM(SUM(order_revenue)) OVER (), 2) AS pct_of_revenue
FROM v_delivered_orders
GROUP BY order_value_band
ORDER BY order_value_band;

------------------------------------------------------------------------
-- LEVEL 2 - JOINS, HAVING, SUBQUERIES, CTEs
------------------------------------------------------------------------

-- Q07: Which product categories earn the most? (LEFT JOIN keeps products
--      whose category is missing or has no English translation)
SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       COUNT(*)                                 AS items_sold,
       COUNT(DISTINCT i.order_id)               AS orders,
       SUM(i.price + i.freight_value)           AS revenue,
       ROUND(AVG(i.price), 2)                   AS avg_item_price
FROM order_items i
INNER JOIN orders o                ON o.order_id = i.order_id
INNER JOIN products p              ON p.product_id = i.product_id
LEFT JOIN category_translation t   ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY 1
ORDER BY revenue DESC
LIMIT 15;

-- Q08: Data quality - which orders have no items or no payment? (LEFT JOIN ... IS NULL)
SELECT o.order_status,
       COUNT(*) FILTER (WHERE i.order_id IS NULL) AS orders_without_items,
       COUNT(*) FILTER (WHERE p.order_id IS NULL) AS orders_without_payment
FROM orders o
LEFT JOIN (SELECT DISTINCT order_id FROM order_items)    i ON i.order_id = o.order_id
LEFT JOIN (SELECT DISTINCT order_id FROM order_payments) p ON p.order_id = o.order_id
GROUP BY o.order_status
HAVING COUNT(*) FILTER (WHERE i.order_id IS NULL OR p.order_id IS NULL) > 0
ORDER BY orders_without_items DESC;

-- Q09: Which states (500+ orders) have the slowest and most often late deliveries? (HAVING)
SELECT customer_state,
       COUNT(*)                                               AS orders,
       ROUND(AVG(delivery_days), 1)                           AS avg_delivery_days,
       ROUND(100.0 * AVG(CASE WHEN delay_days > 0 THEN 1 ELSE 0 END), 2) AS late_rate_pct,
       ROUND(AVG(review_score), 2)                            AS avg_review_score
FROM v_delivered_orders
WHERE delay_days IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 500
ORDER BY late_rate_pct DESC;

-- Q10: How does delivery timing affect the review score? (CASE WHEN + aggregates)
SELECT CASE
           WHEN delay_days <= -8 THEN '1. 8+ days early'
           WHEN delay_days <=  0 THEN '2. 0-7 days early'
           WHEN delay_days <=  7 THEN '3. 1-7 days late'
           ELSE                       '4. 8+ days late'
       END                                                     AS delivery_status,
       COUNT(*)                                                AS orders,
       ROUND(AVG(review_score), 2)                             AS avg_review_score,
       ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 2) AS pct_1_or_2_stars
FROM v_delivered_orders
WHERE delay_days IS NOT NULL
GROUP BY delivery_status
ORDER BY delivery_status;

-- Q11: On which weekdays do customers place the most orders? (EXTRACT)
SELECT EXTRACT(ISODOW FROM order_purchase_timestamp)::int  AS weekday_no,   -- 1 = Monday
       TO_CHAR(order_purchase_timestamp, 'FMDay')           AS weekday,
       COUNT(*)                                              AS orders,
       SUM(order_revenue)                                    AS revenue
FROM v_delivered_orders
GROUP BY weekday_no, weekday
ORDER BY weekday_no;

-- Q12: How many customers came back for a second order? (CTE)
WITH customer_orders AS (
    SELECT customer_unique_id,
           COUNT(*)           AS orders,
           SUM(order_revenue) AS revenue
    FROM v_delivered_orders
    GROUP BY customer_unique_id
)
SELECT COUNT(*)                                             AS customers,
       COUNT(*) FILTER (WHERE orders >= 2)                  AS repeat_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE orders >= 2) / COUNT(*), 2) AS repeat_rate_pct,
       ROUND(AVG(revenue) FILTER (WHERE orders >= 2), 2)    AS avg_spend_repeat,
       ROUND(AVG(revenue) FILTER (WHERE orders = 1), 2)     AS avg_spend_one_time,
       ROUND(100.0 * SUM(revenue) FILTER (WHERE orders >= 2) / SUM(revenue), 2) AS repeat_revenue_share_pct
FROM customer_orders;

-- Q13: Which categories earn more than the average category? (subquery in HAVING)
SELECT category,
       SUM(item_revenue) AS revenue
FROM v_delivered_items
GROUP BY category
HAVING SUM(item_revenue) > (
    SELECT AVG(category_revenue)
    FROM (SELECT SUM(item_revenue) AS category_revenue
          FROM v_delivered_items
          GROUP BY category) AS per_category
)
ORDER BY revenue DESC;

------------------------------------------------------------------------
-- LEVEL 3 - WINDOW FUNCTIONS (LAG, LEAD, running totals, ranking)
------------------------------------------------------------------------

-- Q14: What is the month-over-month revenue growth? (LAG)
WITH monthly AS (
    SELECT purchase_month,
           SUM(order_revenue) AS revenue
    FROM v_delivered_orders
    GROUP BY purchase_month
)
SELECT TO_CHAR(purchase_month, 'YYYY-MM')                     AS month,
       revenue,
       LAG(revenue) OVER (ORDER BY purchase_month)            AS previous_month_revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY purchase_month))
             / LAG(revenue) OVER (ORDER BY purchase_month), 2) AS mom_growth_pct
FROM monthly
ORDER BY purchase_month;

-- Q15: What is the running (year-to-date) revenue in each year? (running total)
WITH monthly AS (
    SELECT purchase_month,
           SUM(order_revenue) AS revenue
    FROM v_delivered_orders
    GROUP BY purchase_month
)
SELECT EXTRACT(YEAR FROM purchase_month)::int AS year,
       TO_CHAR(purchase_month, 'YYYY-MM')     AS month,
       revenue,
       SUM(revenue) OVER (PARTITION BY EXTRACT(YEAR FROM purchase_month)
                          ORDER BY purchase_month
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ytd_revenue
FROM monthly
ORDER BY purchase_month;

-- Q16: What are the top 3 categories in each region? (DENSE_RANK)
WITH region_category AS (
    SELECT customer_region,
           category,
           SUM(item_revenue) AS revenue
    FROM v_delivered_items
    GROUP BY customer_region, category
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY customer_region ORDER BY revenue DESC) AS category_rank
    FROM region_category
)
SELECT customer_region, category_rank, category, revenue
FROM ranked
WHERE category_rank <= 3
ORDER BY customer_region, category_rank;

-- Q17: What are the 3 best-selling products in each of the top 5 categories? (ROW_NUMBER)
WITH top_categories AS (
    SELECT category
    FROM v_delivered_items
    GROUP BY category
    ORDER BY SUM(item_revenue) DESC
    LIMIT 5
),
product_sales AS (
    SELECT di.category,
           di.product_id,
           COUNT(*)             AS units_sold,
           SUM(di.item_revenue) AS revenue
    FROM v_delivered_items di
    JOIN top_categories tc ON tc.category = di.category
    GROUP BY di.category, di.product_id
)
SELECT category, product_rank, product_id, units_sold, revenue
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC, product_id) AS product_rank
    FROM product_sales
) ranked
WHERE product_rank <= 3
ORDER BY category, product_rank;

-- Q18: How concentrated is revenue across categories? (RANK + cumulative share / Pareto)
WITH category_revenue AS (
    SELECT category,
           SUM(item_revenue) AS revenue
    FROM v_delivered_items
    GROUP BY category
)
SELECT RANK() OVER (ORDER BY revenue DESC)                              AS category_rank,
       category,
       revenue,
       ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)                 AS revenue_share_pct,
       ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             / SUM(revenue) OVER (), 2)                                 AS cumulative_share_pct
FROM category_revenue
ORDER BY category_rank
LIMIT 20;

-- Q19: How much revenue do the top 10% of sellers generate? (NTILE)
WITH seller_revenue AS (
    SELECT seller_id,
           SUM(item_revenue) AS revenue
    FROM v_delivered_items
    GROUP BY seller_id
),
deciles AS (
    SELECT seller_id,
           revenue,
           NTILE(10) OVER (ORDER BY revenue DESC) AS revenue_decile   -- 1 = top 10%
    FROM seller_revenue
)
SELECT revenue_decile,
       COUNT(*)                                           AS sellers,
       SUM(revenue)                                       AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2) AS revenue_share_pct
FROM deciles
GROUP BY revenue_decile
ORDER BY revenue_decile;

-- Q20: RFM-style customer segments - how many customers and how much revenue?
--      Quartile thresholds are calculated with PERCENTILE_CONT (same method as pandas .quantile()).
WITH customers_rfm AS (
    SELECT customer_unique_id,
           COUNT(*)                                     AS orders,
           SUM(order_revenue)                           AS revenue,
           DATE '2018-09-01' - MAX(purchase_date)       AS recency_days
    FROM v_delivered_orders
    GROUP BY customer_unique_id
),
thresholds AS (
    SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY recency_days) AS r25,
           PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY recency_days) AS r50,
           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue)      AS m75
    FROM customers_rfm
),
segmented AS (
    SELECT c.*,
           CASE
               WHEN c.orders >= 2                                   THEN 'Repeat customers'
               WHEN c.revenue >  t.m75 AND c.recency_days <= t.r50  THEN 'High-value recent'
               WHEN c.revenue >  t.m75                              THEN 'High-value lapsed'
               WHEN c.recency_days <= t.r50                         THEN 'Regular recent'
               ELSE                                                      'Regular lapsed'
           END AS segment
    FROM customers_rfm c
    CROSS JOIN thresholds t
)
SELECT segment,
       COUNT(*)                                               AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)     AS customer_share_pct,
       SUM(revenue)                                           AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2) AS revenue_share_pct,
       ROUND(AVG(revenue), 2)                                 AS avg_spend,
       ROUND(AVG(recency_days), 1)                            AS avg_recency_days
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;

-- Q21: For customers who came back, how long did they take to place the 2nd order? (LEAD)
WITH customer_orders AS (
    SELECT customer_unique_id,
           purchase_date,
           ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp, order_id) AS order_no,
           LEAD(purchase_date) OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp, order_id) AS next_purchase_date
    FROM v_delivered_orders
),
first_gap AS (
    SELECT customer_unique_id,
           next_purchase_date - purchase_date AS days_to_second_order
    FROM customer_orders
    WHERE order_no = 1 AND next_purchase_date IS NOT NULL
)
SELECT CASE
           WHEN days_to_second_order = 0    THEN '1. Same day'
           WHEN days_to_second_order <= 30  THEN '2. 1-30 days'
           WHEN days_to_second_order <= 90  THEN '3. 31-90 days'
           WHEN days_to_second_order <= 180 THEN '4. 91-180 days'
           ELSE                                  '5. 181+ days'
       END                                                    AS time_to_second_order,
       COUNT(*)                                               AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)     AS pct_of_repeat_customers
FROM first_gap
GROUP BY time_to_second_order
ORDER BY time_to_second_order;

-- Q22: Year-over-year: how did Jan-Aug 2018 compare with Jan-Aug 2017? (conditional aggregation)
WITH jan_aug AS (
    SELECT EXTRACT(YEAR FROM purchase_date)::int AS year,
           order_revenue,
           customer_unique_id
    FROM v_delivered_orders
    WHERE EXTRACT(MONTH FROM purchase_date) <= 8
),
by_year AS (
    SELECT SUM(order_revenue) FILTER (WHERE year = 2017)               AS revenue_2017,
           SUM(order_revenue) FILTER (WHERE year = 2018)               AS revenue_2018,
           COUNT(*) FILTER (WHERE year = 2017)                         AS orders_2017,
           COUNT(*) FILTER (WHERE year = 2018)                         AS orders_2018
    FROM jan_aug
)
SELECT revenue_2017,
       revenue_2018,
       ROUND(100.0 * (revenue_2018 - revenue_2017) / revenue_2017, 2) AS revenue_growth_pct,
       orders_2017,
       orders_2018,
       ROUND(100.0 * (orders_2018 - orders_2017) / orders_2017, 2)    AS order_growth_pct,
       ROUND(revenue_2017 / orders_2017, 2)                            AS aov_2017,
       ROUND(revenue_2018 / orders_2018, 2)                            AS aov_2018
FROM by_year;

-- Q23: How big was Black Friday 2017 compared with a normal day? (7-day moving average window)
WITH daily AS (
    SELECT purchase_date,
           COUNT(*)           AS orders,
           SUM(order_revenue) AS revenue
    FROM v_delivered_orders
    GROUP BY purchase_date
),
with_average AS (
    SELECT purchase_date,
           orders,
           revenue,
           ROUND(AVG(revenue) OVER (ORDER BY purchase_date
                                    ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING), 2) AS avg_revenue_previous_7_days,
           RANK() OVER (ORDER BY revenue DESC)                                   AS revenue_rank
    FROM daily
)
SELECT purchase_date,
       TO_CHAR(purchase_date, 'FMDay')                          AS weekday,
       orders,
       revenue,
       avg_revenue_previous_7_days,
       ROUND(revenue / avg_revenue_previous_7_days, 1)          AS times_previous_week_avg,
       revenue_rank
FROM with_average
WHERE purchase_date BETWEEN DATE '2017-11-20' AND DATE '2017-11-28'
ORDER BY purchase_date;
