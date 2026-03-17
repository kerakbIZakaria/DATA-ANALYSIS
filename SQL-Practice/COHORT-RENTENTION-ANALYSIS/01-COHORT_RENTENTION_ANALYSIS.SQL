WITH first_purchase AS (
    SELECT 
        customerkey,
        DATE_TRUNC('month', MIN(orderdate))::date AS cohort_month
    FROM sales
    GROUP BY customerkey
),
orders_with_cohort AS (
    SELECT 
        s.customerkey,
        DATE_TRUNC('month', s.orderdate)::date AS order_month,
        fp.cohort_month
    FROM sales s
    JOIN first_purchase fp USING(customerkey)
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customerkey) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
),
month_series AS (
    -- توليد كل combination من cohort_month و month_number (مثلاً 24 شهر للأمام)
    SELECT 
        cohort_month,
        generate_series(0, 24) AS month_number
    FROM cohort_sizes
)
SELECT
    ms.cohort_month,
    ms.month_number,
    COALESCE(COUNT(DISTINCT o.customerkey), 0) AS active_users,
    COALESCE((COUNT(DISTINCT o.customerkey)::float / c.cohort_size)*100, 0) AS retention_rate
FROM month_series ms
LEFT JOIN orders_with_cohort o
    ON o.cohort_month = ms.cohort_month
   AND ((EXTRACT(YEAR FROM o.order_month) - EXTRACT(YEAR FROM o.cohort_month)) * 12 +
        (EXTRACT(MONTH FROM o.order_month) - EXTRACT(MONTH FROM o.cohort_month))) = ms.month_number
JOIN cohort_sizes c
    ON ms.cohort_month = c.cohort_month
GROUP BY ms.cohort_month, ms.month_number, c.cohort_size
ORDER BY ms.cohort_month, ms.month_number;

