/* =====================================================================
   Cleaning layer: views that apply the SAME rules as the Python notebook
   (see docs/data_cleaning.md). The raw tables are never changed.
   Run after load_data.sql:   psql -d olist_db -f sql/cleaning_views.sql

   Definitions used everywhere:
     revenue         = item price + freight_value
     delivered order = order_status = 'delivered'
     analysis window = purchases from 2017-01-01 to 2018-08-31
     delivery_days   = customer delivery timestamp - purchase timestamp (days)
     delay_days      = delivery date - estimated delivery date (late if > 0)
   ===================================================================== */

SET search_path TO olist;

-- 1) Products with a clean English category name
CREATE OR REPLACE VIEW v_products AS
WITH english AS (
    SELECT p.product_id,
           p.product_category_name AS category_pt,
           CASE
               WHEN p.product_category_name IS NULL THEN 'unknown'
               WHEN p.product_category_name = 'pc_gamer' THEN 'pc_gamer'
               WHEN p.product_category_name = 'portateis_cozinha_e_preparadores_de_alimentos' THEN 'portable_kitchen_food_preparers'
               WHEN t.product_category_name_english = 'fashio_female_clothing' THEN 'fashion_female_clothing'
               WHEN t.product_category_name_english = 'costruction_tools_garden' THEN 'construction_tools_garden'
               WHEN t.product_category_name_english = 'costruction_tools_tools' THEN 'construction_tools_tools'
               WHEN t.product_category_name_english = 'home_confort' THEN 'home_comfort'
               ELSE t.product_category_name_english
           END AS category_en
    FROM products p
    LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
)
SELECT product_id,
       category_pt,
       -- 'bed_bath_table' -> 'Bed bath table' (same format as the Python notebook)
       UPPER(LEFT(REPLACE(category_en, '_', ' '), 1)) || LOWER(SUBSTRING(REPLACE(category_en, '_', ' ') FROM 2)) AS category
FROM english;

-- 2) Order level: one row per order with totals, review, delivery metrics and flags
CREATE OR REPLACE VIEW v_orders AS
WITH item_totals AS (
    SELECT order_id,
           COUNT(*)           AS items_count,
           SUM(price)         AS product_revenue,
           SUM(freight_value) AS freight_value
    FROM order_items
    GROUP BY order_id
),
main_item AS (               -- main category = category of the most expensive item
    SELECT i.order_id,
           vp.category AS main_category,
           ROW_NUMBER() OVER (PARTITION BY i.order_id ORDER BY i.price DESC, i.order_item_id) AS rn
    FROM order_items i
    JOIN v_products vp ON vp.product_id = i.product_id
),
payment_rank AS (            -- main payment type = method that paid the largest amount
    SELECT order_id,
           payment_type,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_value DESC, payment_sequential) AS rn,
           MAX(GREATEST(payment_installments, 1)) OVER (PARTITION BY order_id) AS max_installments
    FROM order_payments
),
latest_review AS (           -- one review per order: the latest answered one
    SELECT order_id,
           review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC, review_creation_date DESC, review_id DESC) AS rn
    FROM order_reviews
)
SELECT o.order_id,
       c.customer_unique_id,
       c.customer_state,
       s.region                                        AS customer_region,
       o.order_status,
       o.order_purchase_timestamp,
       o.order_purchase_timestamp::date                AS purchase_date,
       DATE_TRUNC('month', o.order_purchase_timestamp)::date AS purchase_month,
       COALESCE(it.items_count, 0)                     AS items_count,
       COALESCE(it.product_revenue, 0)                 AS product_revenue,
       COALESCE(it.freight_value, 0)                   AS freight_value,
       COALESCE(it.product_revenue, 0) + COALESCE(it.freight_value, 0) AS order_revenue,
       mi.main_category,
       pr.payment_type                                 AS primary_payment_type,
       pr.max_installments,
       lr.review_score,
       CASE WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
            THEN ROUND((EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0)::numeric, 2)
       END                                             AS delivery_days,
       CASE WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
            THEN o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date
       END                                             AS delay_days,
       (o.order_status = 'delivered')                  AS is_delivered,
       (o.order_status IN ('canceled', 'unavailable')) AS is_canceled,
       (o.order_purchase_timestamp >= DATE '2017-01-01'
        AND o.order_purchase_timestamp < DATE '2018-09-01') AS in_analysis_window
FROM orders o
JOIN customers c           ON c.customer_id = o.customer_id
LEFT JOIN states s         ON s.state_code = c.customer_state
LEFT JOIN item_totals it   ON it.order_id = o.order_id
LEFT JOIN main_item mi     ON mi.order_id = o.order_id AND mi.rn = 1
LEFT JOIN payment_rank pr  ON pr.order_id = o.order_id AND pr.rn = 1
LEFT JOIN latest_review lr ON lr.order_id = o.order_id AND lr.rn = 1;

-- 3) Analysis scope used by every KPI: delivered orders inside the analysis window
CREATE OR REPLACE VIEW v_delivered_orders AS
SELECT *
FROM v_orders
WHERE is_delivered AND in_analysis_window;

-- 4) Item level for delivered orders in the window (category / product / seller analysis)
CREATE OR REPLACE VIEW v_delivered_items AS
SELECT i.order_id,
       i.order_item_id,
       i.product_id,
       i.seller_id,
       vp.category,
       se.seller_state,
       d.customer_state,
       d.customer_region,
       d.purchase_date,
       d.purchase_month,
       i.price,
       i.freight_value,
       i.price + i.freight_value AS item_revenue
FROM order_items i
JOIN v_delivered_orders d ON d.order_id = i.order_id
JOIN v_products vp        ON vp.product_id = i.product_id
JOIN sellers se           ON se.seller_id = i.seller_id;
