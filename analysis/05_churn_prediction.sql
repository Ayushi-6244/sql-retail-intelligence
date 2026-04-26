-- ============================================================
--  SQL RETAIL INTELLIGENCE ENGINE
--  File: 05_churn_prediction.sql
--  Technique: CASE logic, DATEDIFF, Subqueries, Customer LTV
--  Business Question: Which customers are about to churn?
-- ============================================================

-- STEP 1: Build full customer health profile
WITH customer_activity AS (
    SELECT
        c.customer_id,
        c.name,
        c.city,
        c.segment,
        c.signup_date,
        COUNT(o.order_id)                          AS total_orders,
        ROUND(SUM(o.total_amount), 2)              AS lifetime_value,
        ROUND(AVG(o.total_amount), 2)              AS avg_order_value,
        MIN(o.order_date)                          AS first_order_date,
        MAX(o.order_date)                          AS last_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date))     AS days_since_last_order,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS customer_lifespan_days
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
                       AND o.status = 'Completed'
    GROUP BY c.customer_id, c.name, c.city, c.segment, c.signup_date
),

-- STEP 2: Calculate average purchase gap (how often they normally buy)
avg_gap AS (
    SELECT
        customer_id,
        CASE
            WHEN COUNT(order_id) > 1
            THEN ROUND(
                DATEDIFF(MAX(order_date), MIN(order_date))
                / NULLIF(COUNT(order_id) - 1, 0)
            , 0)
            ELSE NULL
        END AS avg_days_between_orders
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id
),

-- STEP 3: Combine and score churn risk
churn_profile AS (
    SELECT
        a.*,
        g.avg_days_between_orders,

        -- Is this customer overdue based on their own buying pattern?
        CASE
            WHEN g.avg_days_between_orders IS NULL THEN 'One-Time Buyer'
            WHEN a.days_since_last_order > g.avg_days_between_orders * 2 THEN 'Overdue'
            WHEN a.days_since_last_order > g.avg_days_between_orders * 1.5 THEN 'Late'
            ELSE 'On Track'
        END AS purchase_pattern_status,

        -- Rule-based churn risk flag
        CASE
            WHEN a.days_since_last_order > 180 THEN 'Lost'
            WHEN a.days_since_last_order > 90  THEN 'High Risk'
            WHEN a.days_since_last_order > 45  THEN 'Medium Risk'
            WHEN a.days_since_last_order > 20  THEN 'Low Risk'
            ELSE 'Active'
        END AS churn_risk
    FROM customer_activity a
    LEFT JOIN avg_gap g ON a.customer_id = g.customer_id
)

-- FINAL: Prioritized churn watchlist
SELECT
    customer_id,
    name,
    city,
    segment,
    total_orders,
    lifetime_value,
    avg_order_value,
    avg_days_between_orders,
    last_order_date,
    days_since_last_order,
    purchase_pattern_status,
    churn_risk,
    -- Priority score: high LTV + high risk = act first!
    CASE
        WHEN churn_risk IN ('High Risk','Lost') AND lifetime_value > 200 THEN '🔴 URGENT — VIP at Risk'
        WHEN churn_risk IN ('High Risk','Lost')                          THEN '🟠 HIGH — Needs Winback'
        WHEN churn_risk = 'Medium Risk'                                  THEN '🟡 MEDIUM — Monitor'
        ELSE                                                                  '🟢 LOW — Healthy'
    END AS action_priority
FROM churn_profile
ORDER BY
    CASE churn_risk
        WHEN 'Lost'        THEN 1
        WHEN 'High Risk'   THEN 2
        WHEN 'Medium Risk' THEN 3
        WHEN 'Low Risk'    THEN 4
        ELSE 5
    END,
    lifetime_value DESC;


-- ============================================================
-- BONUS: Churn risk summary by segment
-- ============================================================
WITH activity AS (
    SELECT
        c.customer_id,
        c.segment,
        DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_inactive
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
    GROUP BY c.customer_id, c.segment
),
labeled AS (
    SELECT *,
        CASE
            WHEN days_inactive > 180 THEN 'Lost'
            WHEN days_inactive > 90  THEN 'High Risk'
            WHEN days_inactive > 45  THEN 'Medium Risk'
            ELSE 'Active'
        END AS churn_risk
    FROM activity
)
SELECT
    segment,
    churn_risk,
    COUNT(*) AS customer_count
FROM labeled
GROUP BY segment, churn_risk
ORDER BY segment,
    CASE churn_risk WHEN 'Lost' THEN 1 WHEN 'High Risk' THEN 2 WHEN 'Medium Risk' THEN 3 ELSE 4 END;
