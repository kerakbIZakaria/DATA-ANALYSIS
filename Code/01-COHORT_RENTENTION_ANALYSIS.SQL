-- ---------- Cohort Retention Analysis ----------
-- Goal: Track monthly retention of customers and calculate retention rate

WITH first_purchase AS (
    -- Find first purchase date for each customer
    SELECT 
        customerkey,
        DATE_TRUNC('month', MIN(orderdate))::date AS cohort_month
    FROM sales
    GROUP BY customerkey
),

orders_with_cohort AS (
    -- Associate each order with the customer's cohort
    SELECT 
        s.customerkey,
        DATE_TRUNC('month', s.orderdate)::date AS order_month,
        fp.cohort_month
    FROM sales s
    JOIN first_purchase fp
    USING(customerkey)
),

cohort_sizes AS (
    -- Count number of customers in each cohort
    SELECT 
        cohort_month,
        COUNT(DISTINCT customerkey) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
)

SELECT
    o.cohort_month,
    -- Calculate exact month number from cohort (handles multiple years)
    (EXTRACT(YEAR FROM o.order_month) - EXTRACT(YEAR FROM o.cohort_month)) * 12 +
    (EXTRACT(MONTH FROM o.order_month) - EXTRACT(MONTH FROM o.cohort_month)) AS month_number,
    COUNT(DISTINCT o.customerkey) AS active_users,
    -- Calculate retention rate relative to cohort size
    COUNT(DISTINCT o.customerkey)::float / c.cohort_size AS retention_rate
FROM orders_with_cohort o
JOIN cohort_sizes c
ON o.cohort_month = c.cohort_month
GROUP BY o.cohort_month, month_number, c.cohort_size
ORDER BY o.cohort_month, month_number;