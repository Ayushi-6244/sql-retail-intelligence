-- ============================================================
--  SQL RETAIL INTELLIGENCE ENGINE
--  File: 01_customer_segmentation.sql
--  Technique: RFM Analysis (Recency, Frequency, Monetary)
--  Business Question: Who are our most valuable customers?
-- ============================================================

-- STEP 1: Calculate raw RFM values per customer
WITH rfm_base AS (
    SELECT
        c.customer_id,
        c.name,
        c.city,
        c.segment,
        MAX(o.order_date)                          AS last_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date))     AS recency_days,
        COUNT(o.order_id)                          AS frequency,
        ROUND(SUM(o.total_amount), 2)              AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.name, c.city, c.segment
),

-- STEP 2: Score each customer 1-4 using NTILE window function
rfm_scored AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY recency_days ASC)  AS r_score,  -- lower days = better
        NTILE(4) OVER (ORDER BY frequency DESC)    AS f_score,  -- more orders = better
        NTILE(4) OVER (ORDER BY monetary DESC)     AS m_score   -- more spend = better
    FROM rfm_base
),

-- STEP 3: Assign human-readable segment labels
rfm_labeled AS (
    SELECT *,
        CONCAT(r_score, f_score, m_score) AS rfm_code,
        CASE
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champion'
            WHEN r_score >= 3 AND f_score >= 2                  THEN 'Loyal Customer'
            WHEN r_score = 4                                     THEN 'Recent Customer'
            WHEN f_score >= 3 AND m_score >= 3                  THEN 'Big Spender'
            WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
            WHEN r_score = 1                                     THEN 'Lost'
            ELSE                                                      'Needs Attention'
        END AS rfm_segment
    FROM rfm_scored
)

-- FINAL OUTPUT: Full customer RFM report
SELECT
    customer_id,
    name,
    city,
    segment          AS account_type,
    last_order_date,
    recency_days,
    frequency        AS total_orders,
    monetary         AS total_spent,
    rfm_code,
    rfm_segment
FROM rfm_labeled
ORDER BY monetary DESC;

-- ============================================================
-- BONUS: Segment Summary — how many customers per label?
-- ============================================================
WITH rfm_base AS (
    SELECT
        c.customer_id,
        MAX(o.order_date)                        AS last_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date))   AS recency_days,
        COUNT(o.order_id)                        AS frequency,
        SUM(o.total_amount)                      AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id
),
rfm_scored AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY recency_days ASC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency DESC)   AS f_score,
        NTILE(4) OVER (ORDER BY monetary DESC)    AS m_score
    FROM rfm_base
),
rfm_labeled AS (
    SELECT *,
        CASE
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champion'
            WHEN r_score >= 3 AND f_score >= 2                  THEN 'Loyal Customer'
            WHEN r_score = 4                                     THEN 'Recent Customer'
            WHEN f_score >= 3 AND m_score >= 3                  THEN 'Big Spender'
            WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
            WHEN r_score = 1                                     THEN 'Lost'
            ELSE                                                      'Needs Attention'
        END AS rfm_segment
    FROM rfm_scored
)
SELECT
    rfm_segment,
    COUNT(*)                    AS customer_count,
    ROUND(AVG(monetary), 2)    AS avg_spend,
    ROUND(AVG(recency_days),1) AS avg_days_since_purchase
FROM rfm_labeled
GROUP BY rfm_segment
ORDER BY avg_spend DESC;
