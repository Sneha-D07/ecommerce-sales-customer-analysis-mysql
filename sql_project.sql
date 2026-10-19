-- Create the database for the Olist E-commerce Analysis project
CREATE DATABASE olist_ecommerce;

-- Select the database to use
USE olist_ecommerce;


-- Create the customers table to store customer information
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

DESCRIBE customers;


-- Create the products table to store product details and dimensions
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

USE olist_ecommerce;

-- Create the orders table to store order status and timestamps
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,

    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

USE olist_ecommerce;

-- Create the order_items table to store products purchased,
-- item prices, and freight charges for each order
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(12,2),
    freight_value DECIMAL(12,2),

    PRIMARY KEY (order_id, order_item_id),

    FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);


USE olist_ecommerce;

SHOW TABLES;

-- Count the total number of records in each table
-- to verify that the data has been imported
SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;


SELECT COUNT(*) FROM customers;


SELECT COUNT(*) AS total_customers
FROM customers;

SELECT COUNT(*) AS total_products
FROM products;


SELECT COUNT(*) AS total_orders
FROM orders;


USE olist_ecommerce;

SELECT COUNT(*) AS total_order_items
FROM order_items;


USE olist_ecommerce;

-- Join customers, orders, order_items, and products
-- to view order details with customer and product information
SELECT
    o.order_id,
    o.order_status,
    c.customer_city,
    oi.product_id,
    oi.price,
    oi.freight_value
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LIMIT 10;


USE olist_ecommerce;

-- Calculate total revenue, total freight charges,
-- number of delivered orders, and total items sold
SELECT
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(SUM(oi.freight_value), 2) AS total_freight,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_items_sold
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


-- Identify the top 10 product categories
-- based on revenue from delivered orders
SELECT
    COALESCE(p.product_category_name, 'unknown') AS category,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(*) AS items_sold
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(p.product_category_name, 'unknown')
ORDER BY total_revenue DESC
LIMIT 10;


-- Identify the top 10 customers by total spending
-- and count their delivered orders
SELECT
    o.customer_id,
    c.customer_city,
    ROUND(SUM(oi.price), 2) AS total_spent,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    o.customer_id,
    c.customer_city
ORDER BY total_spent DESC
LIMIT 10;


-- 8. Identify repeat customers who have placed
-- more than one delivered order
SELECT
    c.customer_unique_id,
    c.customer_city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    c.customer_unique_id,
    c.customer_city
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY total_orders DESC, total_spent DESC
LIMIT 10;


-- Calculate the percentage of customers
-- who have placed more than one delivered order
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS repeat_customer_percentage
FROM customer_orders;




-- Analyze monthly revenue and order counts
-- to understand sales trends over time
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
        AS order_month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;



-- Rank product categories by revenue
-- using a CTE and the RANK() window function
WITH category_sales AS (
    SELECT
        p.product_category_name AS category,
        SUM(oi.price) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name
)
SELECT
    category,
    ROUND(total_revenue, 2) AS total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_sales
ORDER BY revenue_rank
LIMIT 10;







