-- ============================================================
--  SQL RETAIL INTELLIGENCE ENGINE
--  File: 02_revenue_trends.sql
--  Technique: Window Functions — LAG, Running Total, Moving Avg
--  Business Question: Is revenue growing month-over-month?
-- ============================================================

-- STEP 1: Monthly revenue aggregation
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m')  AS month,
        COUNT(order_id)                   AS total_orders,
        COUNT(DISTINCT customer_id)       AS unique_customers,
        ROUND(SUM(total_amount), 2)       AS revenue,
        ROUND(AVG(total_amount), 2)       AS avg_order_value
    FROM orders
    WHERE status = 'Completed'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),

-- STEP 2: Add MoM growth, running total, and 3-month moving average
revenue_analysis AS (
    SELECT
        month,
        total_orders,
        unique_customers,
        revenue,
        avg_order_value,

        -- Previous month revenue (LAG)
        LAG(revenue) OVER (ORDER BY month)    AS prev_month_revenue,

        -- Month-over-Month growth %
        ROUND(
            (revenue - LAG(revenue) OVER (ORDER BY month))
            / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100
        , 2)                                  AS mom_growth_pct,

        -- Running cumulative revenue
        ROUND(SUM(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2)
                                              AS cumulative_revenue,

        -- 3-month moving average (smooths out noise)
        ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)
                                              AS moving_avg_3m
    FROM monthly_revenue
)

-- FINAL OUTPUT
SELECT
    month,
    total_orders,
    unique_customers,
    revenue,
    avg_order_value,
    prev_month_revenue,
    CONCAT(
        CASE WHEN mom_growth_pct > 0 THEN '+' ELSE '' END,
        mom_growth_pct, '%'
    )                                         AS mom_growth,
    cumulative_revenue,
    moving_avg_3m
FROM revenue_analysis
ORDER BY month;


-- ============================================================
-- BONUS: Best & Worst performing months
-- ============================================================
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        ROUND(SUM(total_amount), 2)      AS revenue
    FROM orders
    WHERE status = 'Completed'
    GROUP BY month
)
SELECT
    month,
    revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM monthly
ORDER BY revenue DESC
LIMIT 5;
