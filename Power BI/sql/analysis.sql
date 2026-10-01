-- Olist E-Commerce Portfolio Analysis
-- Dialect: MySQL 8+
-- Table names assumed: orders, customers, order_items, payments, reviews,
-- products, sellers, category_translation

-- 1. Monthly delivered GMV + month-over-month growth
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS month_start,
        SUM(oi.price) AS delivered_gmv,
        COUNT(DISTINCT o.order_id) AS delivered_orders
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')
),
x AS (
    SELECT *,
           LAG(delivered_gmv) OVER (ORDER BY month_start) AS previous_month_gmv
    FROM monthly
)
SELECT month_start, delivered_gmv, delivered_orders,
       (delivered_gmv - previous_month_gmv) / NULLIF(previous_month_gmv,0) AS mom_growth
FROM x
ORDER BY month_start;

-- 2. Top product categories by delivered GMV
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category,
    SUM(oi.price) AS delivered_gmv,
    SUM(oi.freight_value) AS freight,
    COUNT(DISTINCT o.order_id) AS orders
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN category_translation t
  ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY delivered_gmv DESC;

-- 3. Seller ranking + cumulative GMV share
WITH seller_gmv AS (
    SELECT oi.seller_id,
           SUM(oi.price) AS delivered_gmv,
           COUNT(DISTINCT oi.order_id) AS orders
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
)
SELECT seller_id, delivered_gmv, orders,
       RANK() OVER (ORDER BY delivered_gmv DESC) AS seller_rank,
       SUM(delivered_gmv) OVER (ORDER BY delivered_gmv DESC)
       / SUM(delivered_gmv) OVER () AS cumulative_gmv_share
FROM seller_gmv
ORDER BY seller_rank;

-- 4. Repeat-customer rate
WITH customer_orders AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS unique_customers,
    SUM(order_count > 1) AS repeat_customers,
    AVG(order_count > 1) AS repeat_customer_rate
FROM customer_orders;

-- 5. RFM base
WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(CASE WHEN o.order_status='delivered' THEN oi.price ELSE 0 END) AS monetary
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id
),
rfm AS (
    SELECT *,
        DATEDIFF((SELECT MAX(DATE(order_purchase_timestamp)) FROM orders), last_purchase_date) AS recency_days,
        NTILE(5) OVER (
          ORDER BY DATEDIFF((SELECT MAX(DATE(order_purchase_timestamp)) FROM orders), last_purchase_date) DESC
        ) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM customer_value
)
SELECT * FROM rfm
ORDER BY monetary DESC;

-- 6. Late delivery vs review score
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On time'
    END AS delivery_bucket,
    COUNT(DISTINCT o.order_id) AS orders,
    AVG(r.review_score) AS avg_review_score
FROM orders o
JOIN reviews r ON r.order_id = o.order_id
WHERE o.order_status='delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_bucket;

-- 7. State-level delivery performance
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    AVG(TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp, o.order_delivered_customer_date))/24.0 AS avg_delivery_days,
    AVG(o.order_delivered_customer_date > o.order_estimated_delivery_date) AS late_delivery_rate
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status='delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY delivered_orders DESC;

-- 8. Payment-method share
WITH p AS (
    SELECT payment_type, SUM(payment_value) AS payment_value
    FROM payments
    GROUP BY payment_type
)
SELECT payment_type, payment_value,
       payment_value / SUM(payment_value) OVER () AS payment_value_share
FROM p
ORDER BY payment_value DESC;

-- 9. Product Pareto / cumulative contribution
WITH product_gmv AS (
    SELECT p.product_id,
           COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category,
           SUM(oi.price) AS delivered_gmv
    FROM order_items oi
    JOIN orders o ON o.order_id=oi.order_id
    JOIN products p ON p.product_id=oi.product_id
    LEFT JOIN category_translation t ON t.product_category_name=p.product_category_name
    WHERE o.order_status='delivered'
    GROUP BY p.product_id, category
)
SELECT product_id, category, delivered_gmv,
       SUM(delivered_gmv) OVER (ORDER BY delivered_gmv DESC)
       / SUM(delivered_gmv) OVER () AS cumulative_gmv_share
FROM product_gmv
ORDER BY delivered_gmv DESC;
