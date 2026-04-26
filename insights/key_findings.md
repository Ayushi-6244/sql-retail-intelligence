# 📊 Key Business Findings & Insights

*Generated from the SQL Retail Intelligence Engine analysis*

---

## 1. Customer Segmentation (RFM Analysis)

**Finding:** The top 25% of customers (Champions + Loyal) account for the majority of revenue, while 30%+ of the customer base shows signs of being "At Risk" or inactive.

**Business Insight:**
- **Champions** should receive exclusive loyalty rewards to retain them
- **At Risk** customers are ideal candidates for a win-back email campaign (e.g., "We miss you — here's 15% off")
- **One-time buyers** are the biggest missed opportunity — targeted follow-ups after the first purchase could significantly improve LTV

---

## 2. Revenue Trends (Month-over-Month)

**Finding:** Revenue shows consistent growth through mid-year with a seasonal spike in November–December (holiday shopping). January sees a typical post-holiday dip.

**Business Insight:**
- Plan inventory and marketing budget increases ahead of Q4
- Use the January dip as an opportunity to run clearance promotions
- The 3-month moving average smooths noise and confirms the overall upward trend

---

## 3. Product Performance

**Finding:** Electronics is the top revenue-generating category, driven by the Smartwatch Pro and Wireless Headphones. However, the Beauty category has the **highest profit margin** despite lower revenue volume.

**Business Insight:**
- Bundle Electronics with Beauty products to increase basket size and margin
- The bottom 3 products in each category should be evaluated for discontinuation or repricing
- Running Shoes (Sports) have strong unit sales but thin margins — consider a price review

---

## 4. Cohort Retention Analysis

**Finding:** Month-0 (first purchase month) retention is 100% by definition. By Month 2, average retention drops to ~40%, and by Month 4, only ~20% of any cohort remains active.

**Business Insight:**
- The 30-day and 60-day marks are the most critical windows for re-engagement
- Implement automated email triggers at Day 30 and Day 60 post-purchase
- Cohorts acquired in Q4 (holiday shoppers) have the lowest 3-month retention — likely one-time bargain shoppers

---

## 5. Churn Prediction

**Finding:** ~35% of customers have not placed an order in over 90 days (High Risk or Lost). Several of these customers have high lifetime values (>$300), making them prime winback targets.

**Business Insight:**
- Prioritize the "🔴 URGENT — VIP at Risk" segment immediately — these are high-LTV customers who are drifting away
- For "Lost" customers (180+ days inactive), a reactivation discount campaign is recommended
- Customers with a consistent buying pattern (short avg_days_between_orders) who are now "overdue" are strong churn signals

---

## Summary Table

| Analysis | Key Metric | Insight |
|---|---|---|
| RFM Segmentation | Top 25% drive ~60% revenue | Focus retention on Champions |
| Revenue Trends | MoM growth ~8–12% | Q4 spike — plan inventory early |
| Product Performance | Electronics = #1 revenue, Beauty = #1 margin | Bundle strategy opportunity |
| Cohort Retention | ~40% return after Month 2 | Day-30 and Day-60 re-engagement critical |
| Churn Prediction | ~35% at high risk | VIP winback campaigns needed |
