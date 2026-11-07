 --FR-1    Revenue & Sales Trend Analysis
 
-- Establish the top-line revenue baseline and show how it moves across channel, region and time — the number 
--every other module gets checked against.

 --BQ01-Total recognised revenue by year and month, with MoM and YoY growth.
 
WITH month_spine AS(
SELECT
    GENERATE_SERIES(
        (SELECT MIN(order_date)::date FROM sales_orders),
        (SELECT MAX(order_date)::date FROM sales_orders),
        INTERVAL '1 month'
    )::date AS month_start
),
revenue_data AS(
SELECT 
date_trunc('month', so.order_date )::date AS month_start,
sum(so.total_amount) AS revenue
FROM sales_orders so 
WHERE so.order_status = 'Delivered'
GROUP BY month_start 
ORDER BY month_start 
)
SELECT
	ms.month_start,
	rd.revenue,
	COALESCE(round((rd.revenue -lag(rd.revenue)OVER(ORDER BY ms.month_start ASC))* 100.0 /
lag(rd.revenue)OVER(ORDER BY ms.month_start ASC), 2), 0) AS MoM_growth,
	COALESCE(round((rd.revenue -lag(rd.revenue, 12)OVER(ORDER BY ms.month_start ASC))* 100.0 /
lag(rd.revenue, 12)OVER(ORDER BY ms.month_start ASC), 2), 0) AS YoY_growth
FROM
	month_spine ms
LEFT JOIN revenue_data rd ON
	ms.month_start = rd.month_start




-- BQ02-Calculate Average Order Value & Volume By Channel
SELECT
	channel,
	avg(so.total_amount) AS avg_value,
	count(so.order_id)
FROM
	sales_orders so
WHERE
	so.order_status = 'Delivered'
GROUP BY
	so.channel
	
	
	
--BQ03- Revenue leaders and laggards by region.

WITH regional_data AS(
SELECT 
so.channel, so.total_amount, COALESCE(d.region, rc.region)AS region
FROM sales_orders so LEFT JOIN 
dealers d ON d.dealer_id = so.dealer_id 
LEFT JOIN retail_customers rc ON rc.customer_id = so.customer_id 
)
SELECT
	COALESCE(region, 'Grand Total') AS region,
	sum(total_amount)FILTER(WHERE channel = 'RETAIL')AS retail,
	sum(total_amount)FILTER(WHERE channel = 'ONLINE')AS online,
	sum(total_amount)FILTER(WHERE channel = 'DEALER')AS dealer,
	sum(total_amount)AS total_revenue
FROM
	regional_data
GROUP BY
	ROLLUP(region)
ORDER BY
	GROUPING(region),
	total_revenue DESC
	
	
--BQ04-Revenue lost to cancellations, and discount rate as a % of gross.
WITH calculated_table AS(
SELECT 
date_trunc('month', so.order_date)::date AS month_start,
sum(so.total_amount)FILTER(WHERE so.order_status = 'Delivered' )AS booked_revenue,
sum(so.total_amount)FILTER(WHERE so.order_status = 'Cancelled' )AS cancelled_revenue,
sum(so.discount_amount)FILTER(WHERE so.order_status = 'Delivered' )AS discounted_amount,
sum(so.subtotal)FILTER(WHERE so.order_status = 'Delivered' )AS gross_amount
FROM 
sales_orders so 
GROUP BY month_start 
)
SELECT
	month_start,
	round((cancelled_revenue * 100.0)/
NULLIF((booked_revenue + cancelled_revenue), 0), 2)AS cancelled_pct,
	round((discounted_amount * 100.0)/ NULLIF(gross_amount, 0), 2) AS discount_pct
FROM
	calculated_table
ORDER BY
	month_start