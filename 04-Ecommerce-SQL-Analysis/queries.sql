-- ============================================================
-- E-commerce Sales Analysis — SQL Queries
-- Database: ecommerce_analytics (MySQL)
-- ============================================================

-- ------------------------------------------------------------
-- 1. TABLE SETUP
-- ------------------------------------------------------------

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    region VARCHAR(50),
    signup_date DATE,
    customer_segment VARCHAR(50)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_cost DECIMAL(10,2),
    unit_price DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    sales_channel VARCHAR(50),
    order_status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Staging table with no FK constraint, used to isolate line items
-- referencing product_ids that don't exist in `products` (see README).
CREATE TABLE order_items_orphaned (
    order_item_id INT,
    order_id INT,
    product_id INT,
    quantity INT
);

-- ------------------------------------------------------------
-- 2. DATA LOADING
-- Note: all source CSVs use \n line endings, not \r\n.
-- ------------------------------------------------------------

LOAD DATA LOCAL INFILE 'customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_name, region, signup_date, customer_segment);

LOAD DATA LOCAL INFILE 'products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, category, unit_cost, unit_price);

LOAD DATA LOCAL INFILE 'orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_date, sales_channel, order_status);

-- Loads only the 7,462 rows with a valid product_id (FK enforced);
-- remaining 5,086 rows are rejected here and captured below.
LOAD DATA LOCAL INFILE 'order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_item_id, order_id, product_id, quantity);

-- Load ALL 12,548 rows into the staging table (no FK to reject anything),
-- then keep only the true orphans for documentation purposes.
LOAD DATA LOCAL INFILE 'order_items.csv'
INTO TABLE order_items_orphaned
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_item_id, order_id, product_id, quantity);

DELETE FROM order_items_orphaned
WHERE product_id IN (SELECT product_id FROM products);

-- ------------------------------------------------------------
-- 3. VERIFICATION
-- ------------------------------------------------------------

SELECT COUNT(*) FROM customers;              -- 1,000
SELECT COUNT(*) FROM products;                -- 30
SELECT COUNT(*) FROM orders;                  -- 5,000
SELECT COUNT(*) FROM order_items;             -- 7,462
SELECT COUNT(*) FROM order_items_orphaned;    -- 5,086  (7,462 + 5,086 = 12,548 ✓)

-- ------------------------------------------------------------
-- 4. BASIC JOINS (built up incrementally: 2 tables -> 3 -> 4)
-- ------------------------------------------------------------

-- orders + customers
SELECT o.order_id, o.order_date, c.customer_name, c.region
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LIMIT 10;

-- + order_items (note: row count expands, one row per line item)
SELECT o.order_id, o.order_date, c.customer_name, oi.product_id, oi.quantity
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
LIMIT 10;

-- + products (full 4-table join, with a calculated line_total column)
SELECT o.order_id, o.order_date, c.customer_name, p.product_name, p.category,
       oi.quantity, p.unit_price, (oi.quantity * p.unit_price) AS line_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LIMIT 10;

-- ------------------------------------------------------------
-- 5. TOTAL REVENUE
-- ------------------------------------------------------------

SELECT SUM(oi.quantity * p.unit_price) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id;
-- Result: R195,059,063.31

-- ------------------------------------------------------------
-- 6. TOP PRODUCTS
-- ------------------------------------------------------------

-- By revenue
SELECT p.product_name, p.category,
       SUM(oi.quantity) AS units_sold,
       SUM(oi.quantity * p.unit_price) AS product_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY product_revenue DESC
LIMIT 10;

-- By units sold (a different, more demand-realistic ranking —
-- see README for why unit_price skews the revenue ranking)
SELECT p.product_name, p.category,
       SUM(oi.quantity) AS units_sold,
       SUM(oi.quantity * p.unit_price) AS product_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY units_sold DESC
LIMIT 10;

-- ------------------------------------------------------------
-- 7. REVENUE BY REGION
-- ------------------------------------------------------------

SELECT c.region,
       COUNT(DISTINCT o.order_id) AS num_orders,
       SUM(oi.quantity * p.unit_price) AS region_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.region
ORDER BY region_revenue DESC;
-- Regional totals sum exactly to total_revenue (R195,059,063.31) -- verified.

-- ------------------------------------------------------------
-- 8. TOP SPENDERS (window function)
-- ------------------------------------------------------------

SELECT c.customer_name, c.region,
       SUM(oi.quantity * p.unit_price) AS total_spent,
       RANK() OVER (ORDER BY SUM(oi.quantity * p.unit_price) DESC) AS spend_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.customer_name, c.region
ORDER BY spend_rank
LIMIT 10;

-- ------------------------------------------------------------
-- 9. REPEAT BUYERS (HAVING filters on an aggregate; WHERE cannot)
-- ------------------------------------------------------------

SELECT c.customer_name, c.region,
       COUNT(DISTINCT o.order_id) AS num_orders,
       SUM(oi.quantity * p.unit_price) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.customer_name, c.region
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY num_orders DESC, total_spent DESC
LIMIT 15;
