-- ============================================================
--  SQL RETAIL INTELLIGENCE ENGINE
--  File: executive_dashboard_views.sql
--  Description: Reusable SQL VIEWS for an executive dashboard
--  Run AFTER schema.sql and seed_data.sql
-- ============================================================

-- VIEW 1: KPI Summary (one-row snapshot of business health)
CREATE OR REPLACE VIEW vw_kpi_summary AS
SELECT
    COUNT(DISTINCT c.customer_id)                        AS total_customers,
    COUNT(DISTINCT o.order_id)                           AS total_orders,
    ROUND(SUM(o.total_amount), 2)                        AS total_revenue,
    ROUND(AVG(o.total_amount), 2)                        AS avg_order_value,
    COUNT(DISTINCT CASE WHEN o.status = 'Returned'
                   THEN o.order_id END)                  AS total_returns,
    ROUND(
        COUNT(DISTINCT CASE WHEN o.status = 'Returned'
              THEN o.order_id END)
        / COUNT(DISTINCT o.order_id) * 100, 1
    )                                                    AS return_rate_pct,
    ROUND(SUM(o.total_amount) / COUNT(DISTINCT c.customer_id), 2) AS avg_customer_ltv
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;


-- VIEW 2: Monthly performance (for trend charts)
CREATE OR REPLACE VIEW vw_monthly_performance AS
SELECT
    DATE_FORMAT(order_date, '%Y-%m')    AS month,
    COUNT(order_id)                     AS orders,
    COUNT(DISTINCT customer_id)         AS active_customers,
    ROUND(SUM(total_amount), 2)         AS revenue,
    ROUND(AVG(total_amount), 2)         AS avg_order_value,
    SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS returns
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


-- VIEW 3: Customer 360 — one row per customer with all key metrics
CREATE OR REPLACE VIEW vw_customer_360 AS
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.segment,
    c.signup_date,
    COUNT(o.order_id)                           AS total_orders,
    ROUND(SUM(o.total_amount), 2)               AS lifetime_value,
    ROUND(AVG(o.total_amount), 2)               AS avg_order_value,
    MIN(o.order_date)                           AS first_purchase,
    MAX(o.order_date)                           AS last_purchase,
    DATEDIFF(CURDATE(), MAX(o.order_date))      AS days_since_purchase,
    CASE
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) > 90 THEN 'High Risk'
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) > 45 THEN 'Medium Risk'
        ELSE 'Active'
    END                                         AS churn_risk
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
                   AND o.status = 'Completed'
GROUP BY c.customer_id, c.name, c.city, c.segment, c.signup_date;


-- VIEW 4: Product leaderboard
CREATE OR REPLACE VIEW vw_product_leaderboard AS
SELECT
    p.product_id,
    p.name                                              AS product_name,
    p.category,
    SUM(oi.quantity)                                   AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)        AS revenue,
    ROUND(SUM(oi.quantity * (p.price - p.cost)), 2)   AS gross_profit,
    ROUND(AVG(p.price - p.cost) / AVG(p.price) * 100, 1) AS margin_pct,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_rank
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.name, p.category, p.price, p.cost;


-- ============================================================
-- HOW TO USE THESE VIEWS
-- ============================================================
-- SELECT * FROM vw_kpi_summary;
-- SELECT * FROM vw_monthly_performance;
-- SELECT * FROM vw_customer_360 WHERE churn_risk = 'High Risk';
-- SELECT * FROM vw_product_leaderboard WHERE revenue_rank <= 5;
