/* =====================================================================
   E-commerce Sales & Customer Analytics (Olist) - database schema
   Database : PostgreSQL 13+ (tested on PostgreSQL 16)
   Run      : psql -d olist_db -f sql/schema.sql
   One table per raw CSV file. Column names are kept exactly as in the
   source files (including the original spelling "lenght") so the CSVs
   load without any changes.
   ===================================================================== */

DROP SCHEMA IF EXISTS olist CASCADE;
CREATE SCHEMA olist;
SET search_path TO olist;

-- One row per order-customer id (a new customer_id is created for every order)
CREATE TABLE customers (
    customer_id              TEXT PRIMARY KEY,
    customer_unique_id       TEXT NOT NULL,      -- the real person
    customer_zip_code_prefix CHAR(5),
    customer_city            TEXT,
    customer_state           CHAR(2)
);

CREATE TABLE sellers (
    seller_id              TEXT PRIMARY KEY,
    seller_zip_code_prefix CHAR(5),
    seller_city            TEXT,
    seller_state           CHAR(2)
);

-- Portuguese -> English category names (2 categories are missing in the source)
CREATE TABLE category_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT NOT NULL
);

CREATE TABLE products (
    product_id                 TEXT PRIMARY KEY,
    product_category_name      TEXT,             -- NULL for 610 products
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

CREATE TABLE orders (
    order_id                      TEXT PRIMARY KEY,
    customer_id                   TEXT NOT NULL REFERENCES customers (customer_id),
    order_status                  TEXT NOT NULL,
    order_purchase_timestamp      TIMESTAMP NOT NULL,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- One row per item in an order
CREATE TABLE order_items (
    order_id            TEXT NOT NULL REFERENCES orders (order_id),
    order_item_id       INT  NOT NULL,
    product_id          TEXT NOT NULL REFERENCES products (product_id),
    seller_id           TEXT NOT NULL REFERENCES sellers (seller_id),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10, 2) NOT NULL,
    freight_value       NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

-- One row per payment (an order can be paid with several methods)
CREATE TABLE order_payments (
    order_id             TEXT NOT NULL REFERENCES orders (order_id),
    payment_sequential   INT  NOT NULL,
    payment_type         TEXT NOT NULL,
    payment_installments INT  NOT NULL,
    payment_value        NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

-- review_id is NOT unique on its own in the source data, so the key is (review_id, order_id)
CREATE TABLE order_reviews (
    review_id               TEXT NOT NULL,
    order_id                TEXT NOT NULL REFERENCES orders (order_id),
    review_score            SMALLINT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);

-- Reference table (not from Olist): state names and official IBGE macro-regions
CREATE TABLE states (
    state_code CHAR(2) PRIMARY KEY,
    state_name TEXT NOT NULL,
    region     TEXT NOT NULL
);

INSERT INTO states (state_code, state_name, region) VALUES
    ('AC', 'Acre', 'North'), ('AP', 'Amapá', 'North'), ('AM', 'Amazonas', 'North'), ('PA', 'Pará', 'North'),
    ('RO', 'Rondônia', 'North'), ('RR', 'Roraima', 'North'), ('TO', 'Tocantins', 'North'),
    ('AL', 'Alagoas', 'Northeast'), ('BA', 'Bahia', 'Northeast'), ('CE', 'Ceará', 'Northeast'),
    ('MA', 'Maranhão', 'Northeast'), ('PB', 'Paraíba', 'Northeast'), ('PE', 'Pernambuco', 'Northeast'),
    ('PI', 'Piauí', 'Northeast'), ('RN', 'Rio Grande do Norte', 'Northeast'), ('SE', 'Sergipe', 'Northeast'),
    ('DF', 'Distrito Federal', 'Center-West'), ('GO', 'Goiás', 'Center-West'), ('MT', 'Mato Grosso', 'Center-West'),
    ('MS', 'Mato Grosso do Sul', 'Center-West'),
    ('ES', 'Espírito Santo', 'Southeast'), ('MG', 'Minas Gerais', 'Southeast'), ('RJ', 'Rio de Janeiro', 'Southeast'),
    ('SP', 'São Paulo', 'Southeast'),
    ('PR', 'Paraná', 'South'), ('RS', 'Rio Grande do Sul', 'South'), ('SC', 'Santa Catarina', 'South');

-- Indexes on the columns used for joins and filters
CREATE INDEX idx_customers_unique   ON customers (customer_unique_id);
CREATE INDEX idx_orders_customer    ON orders (customer_id);
CREATE INDEX idx_orders_purchase    ON orders (order_purchase_timestamp);
CREATE INDEX idx_items_product      ON order_items (product_id);
CREATE INDEX idx_items_seller       ON order_items (seller_id);
CREATE INDEX idx_reviews_order      ON order_reviews (order_id);
