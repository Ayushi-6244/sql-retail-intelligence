-- ============================================================
--  SQL RETAIL INTELLIGENCE ENGINE
--  File: 03_product_performance.sql
--  Technique: RANK, PARTITION BY, Profit Margin
--  Business Question: Which products and categories drive the most value?
-- ============================================================

-- STEP 1: Product-level performance with rank inside category
WITH product_stats AS (
    SELECT
        p.product_id,
        p.name                                          AS product_name,
        p.category,
        p.price,
        p.cost,
        ROUND(p.price - p.cost, 2)                     AS unit_margin,
        ROUND((p.price - p.cost) / p.price * 100, 1)  AS margin_pct,
        SUM(oi.quantity)                               AS units_sold,
        ROUND(SUM(oi.quantity * oi.unit_price), 2)    AS revenue,
        ROUND(SUM(oi.quantity * (p.price - p.cost)), 2) AS gross_profit
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders   o ON oi.order_id   = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.product_id, p.name, p.category, p.price, p.cost
),

-- STEP 2: Rank each product within its category
product_ranked AS (
    SELECT *,
        RANK()   OVER (PARTITION BY category ORDER BY revenue DESC)      AS revenue_rank_in_cat,
        RANK()   OVER (PARTITION BY category ORDER BY gross_profit DESC) AS profit_rank_in_cat,
        RANK()   OVER (ORDER BY revenue DESC)                            AS overall_rank
    FROM product_stats
)

-- FINAL: Full product performance report
SELECT
    overall_rank,
    category,
    product_name,
    units_sold,
    revenue,
    gross_profit,
    margin_pct,
    revenue_rank_in_cat,
    profit_rank_in_cat
FROM product_ranked
ORDER BY overall_rank;


-- ============================================================
-- BONUS 1: Category-level summary
-- ============================================================
SELECT
    p.category,
    COUNT(DISTINCT p.product_id)               AS num_products,
    SUM(oi.quantity)                           AS total_units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price) /
        SUM(SUM(oi.quantity * oi.unit_price)) OVER () * 100, 1) AS revenue_share_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.category
ORDER BY total_revenue DESC;


-- ============================================================
-- BONUS 2: Top 3 products per category (podium view)
-- ============================================================
WITH ranked AS (
    SELECT
        p.category,
        p.name,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
        RANK() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rnk
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders   o ON oi.order_id   = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.category, p.name
)
SELECT category, rnk AS rank_in_category, name, revenue
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;
