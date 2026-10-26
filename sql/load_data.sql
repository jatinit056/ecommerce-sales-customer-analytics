/* =====================================================================
   Load the raw CSV files into the olist schema.
   Run this from the PROJECT ROOT folder (paths are relative to it):
       psql -d olist_db -f sql/load_data.sql
   \copy runs on the client, so no superuser rights are needed.
   Load order matters because of the foreign keys.
   ===================================================================== */

\copy olist.customers            FROM 'data/raw/olist_customers_dataset.csv'            WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy olist.sellers              FROM 'data/raw/olist_sellers_dataset.csv'              WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy olist.category_translation FROM 'data/raw/product_category_name_translation.csv'  WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy olist.products             FROM 'data/raw/olist_products_dataset.csv'             WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy olist.orders               FROM 'data/raw/olist_orders_dataset.csv'               WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy olist.order_items          FROM 'data/raw/olist_order_items_dataset.csv'          WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy olist.order_payments       FROM 'data/raw/olist_order_payments_dataset.csv'       WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy olist.order_reviews        FROM 'data/raw/olist_order_reviews_dataset.csv'        WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

ANALYZE;

-- Quick check: row counts must match the CSV files
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM olist.customers
UNION ALL SELECT 'sellers', COUNT(*) FROM olist.sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM olist.category_translation
UNION ALL SELECT 'products', COUNT(*) FROM olist.products
UNION ALL SELECT 'orders', COUNT(*) FROM olist.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM olist.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM olist.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM olist.order_reviews;
