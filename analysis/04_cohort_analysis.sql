-- ============================================================
--  SQL RETAIL INTELLIGENCE ENGINE
--  File: 04_cohort_analysis.sql
--  Technique: Cohort Retention using DATE functions + pivoting
--  Business Question: Do customers come back after their first purchase?
-- ============================================================

-- STEP 1: Assign each customer their cohort (month of first purchase)
WITH customer_cohort AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id
),

-- STEP 2: Get all (customer, order_month) combinations
customer_orders AS (
    SELECT
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m')     AS order_month
    FROM orders o
    WHERE o.status = 'Completed'
),

-- STEP 3: Join to get cohort month alongside each order
cohort_data AS (
    SELECT
        co.customer_id,
        cc.cohort_month,
        co.order_month,
        -- Month index: 0 = first purchase month, 1 = next month, etc.
        PERIOD_DIFF(
            REPLACE(co.order_month,  '-', ''),
            REPLACE(cc.cohort_month, '-', '')
        ) AS month_index
    FROM customer_orders co
    JOIN customer_cohort cc ON co.customer_id = cc.customer_id
),

-- STEP 4: Count unique returning customers per cohort per month_index
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_total
    FROM customer_cohort
    GROUP BY cohort_month
),

retention_raw AS (
    SELECT
        cohort_month,
        month_index,
        COUNT(DISTINCT customer_id) AS active_users
    FROM cohort_data
    GROUP BY cohort_month, month_index
)

-- FINAL: Cohort retention table with % retention
SELECT
    r.cohort_month,
    s.cohort_total                         AS initial_customers,
    r.month_index,
    r.active_users,
    ROUND(r.active_users / s.cohort_total * 100, 1) AS retention_rate_pct
FROM retention_raw r
JOIN cohort_size   s ON r.cohort_month = s.cohort_month
ORDER BY r.cohort_month, r.month_index;


-- ============================================================
-- BONUS: Average retention rate at Month 1, 2, 3 across cohorts
-- ============================================================
WITH customer_cohort AS (
    SELECT customer_id,
           DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM orders WHERE status = 'Completed'
    GROUP BY customer_id
),
customer_orders AS (
    SELECT customer_id,
           DATE_FORMAT(order_date, '%Y-%m') AS order_month
    FROM orders WHERE status = 'Completed'
),
cohort_data AS (
    SELECT co.customer_id, cc.cohort_month, co.order_month,
           PERIOD_DIFF(REPLACE(co.order_month,'-',''), REPLACE(cc.cohort_month,'-','')) AS month_index
    FROM customer_orders co
    JOIN customer_cohort cc ON co.customer_id = cc.customer_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_total
    FROM customer_cohort GROUP BY cohort_month
),
retention_raw AS (
    SELECT cohort_month, month_index, COUNT(DISTINCT customer_id) AS active_users
    FROM cohort_data GROUP BY cohort_month, month_index
)
SELECT
    r.month_index,
    ROUND(AVG(r.active_users / s.cohort_total * 100), 1) AS avg_retention_pct
FROM retention_raw r
JOIN cohort_size s ON r.cohort_month = s.cohort_month
WHERE r.month_index BETWEEN 0 AND 5
GROUP BY r.month_index
ORDER BY r.month_index;
