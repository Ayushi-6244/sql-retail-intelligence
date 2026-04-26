# Query Performance & Optimization Notes

## Why This Matters for a Business Analyst

Real-world databases have millions of rows. Writing correct SQL is only half the job — writing *fast* SQL that scales is what separates junior analysts from senior ones.

---

## Indexes Created (in schema.sql)

| Index Name | Table | Column | Reason |
|---|---|---|---|
| `idx_orders_customer` | orders | customer_id | Speed up all JOIN operations to customers |
| `idx_orders_date` | orders | order_date | Date filtering in revenue & cohort queries |
| `idx_orders_status` | orders | status | Fast `WHERE status = 'Completed'` filtering |
| `idx_items_order` | order_items | order_id | Speed up JOINs from order_items → orders |
| `idx_items_product` | order_items | product_id | Speed up JOINs to products |

**Rule of thumb:** Index columns you frequently `JOIN` on, `WHERE` filter, or `ORDER BY`.

---

## CTE vs Subquery — Why I Used CTEs

In every analysis file, I used **Common Table Expressions (CTEs)** rather than nested subqueries.

**Example from 01_customer_segmentation.sql:**
```sql
-- CTE approach (readable, reusable, easier to debug)
WITH rfm_base AS (
    SELECT customer_id, MAX(order_date) ...
    FROM orders GROUP BY customer_id
),
rfm_scored AS (
    SELECT *, NTILE(4) OVER (...) FROM rfm_base
)
SELECT * FROM rfm_scored;
```

**Advantages of CTEs:**
- Each step is named and readable — like building blocks
- Easier to debug: run each CTE individually to check results
- Avoids deeply nested subqueries which are hard to read
- Some databases (MySQL 8+, PostgreSQL) optimize CTEs well

---

## Window Functions vs GROUP BY

I used both, and here's when I chose each:

| Need | Use |
|---|---|
| Total per group, one row per group | `GROUP BY` |
| Rank/compare rows without collapsing them | `WINDOW FUNCTION` |
| Running total, moving average | `WINDOW FUNCTION` |
| Percent of total per partition | `WINDOW FUNCTION` |

**Example:** In `02_revenue_trends.sql`, I used both:
- `GROUP BY month` to get one revenue row per month
- `LAG() OVER (ORDER BY month)` to compare to the previous month **without a self-join**

---

## NULLIF — Avoiding Division by Zero

In growth calculations:
```sql
-- BAD: crashes if prev_month is 0
(revenue - prev_month) / prev_month * 100

-- GOOD: returns NULL instead of error
(revenue - prev_month) / NULLIF(prev_month, 0) * 100
```

---

## Filtering Early = Faster Queries

Always apply `WHERE` before joins when possible. In all scripts, status filtering happens as early as possible:
```sql
-- More efficient: filter early
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'   -- ← eliminates rows before aggregation
```

---

## EXPLAIN / EXPLAIN ANALYZE (for production)

To check if your query is using indexes:
```sql
EXPLAIN SELECT * FROM orders WHERE status = 'Completed';
```
Look for `type: ref` or `type: range` (good) vs `type: ALL` (full table scan — bad).
