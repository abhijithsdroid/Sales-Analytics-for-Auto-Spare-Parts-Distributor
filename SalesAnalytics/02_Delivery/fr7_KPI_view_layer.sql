 --FR-7    Executive Sales KPI View Layer
 
-- Consolidate FR-1 through FR-6 into a small, reusable set of SQL views a Sales Operations leadership audience 
--could be handed directly — the deliverable the rest of this document builds toward.
 
 
  --BQ28-Monthly Sales Performance Growth 
 
CREATE OR replace VIEW vw_monthly_sales_performance AS
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



SELECT
	*
FROM
	vw_monthly_sales_performance vmsp
  
  
  
  
 --BQ29-Customer Segments 
	
	

CREATE OR replace VIEW vw_customer_segments AS
WITH latest_data AS (
SELECT
	MAX(so.order_date)::DATE AS latest_business_date
FROM
	sales_orders so
),
customer_data AS (
SELECT
	so.customer_id,
	MAX(so.order_date)::DATE AS last_order_date,
	COUNT(*) AS frequency,
	SUM(so.total_amount) AS monetary
FROM
	sales_orders so
WHERE
	so.customer_id IS NOT NULL
GROUP BY
	so.customer_id
),
rfm_values AS (
SELECT
	cd.customer_id,
	ld.latest_business_date - cd.last_order_date AS recency,
	cd.frequency,
	cd.monetary
FROM
	customer_data cd
CROSS JOIN latest_data ld
),
rfm_scores AS (
SELECT
	*,
	NTILE(5) OVER (
	ORDER BY recency DESC) AS rscore,
	NTILE(5) OVER (
	ORDER BY frequency ASC) AS fscore,
	NTILE(5) OVER (
	ORDER BY monetary ASC) AS mscore,
	NTILE(10) OVER (
	ORDER BY monetary ASC) AS decile_value
FROM
	rfm_values
)
SELECT
	customer_id,
	rscore + fscore + mscore AS rfm_score,
	CASE
		WHEN rscore = 5
		AND fscore = 5
		AND mscore = 5
            THEN 'Champion'
		WHEN rscore = 1
		AND fscore = 1
            THEN 'Lost'
		WHEN rscore <= 2
		AND fscore <= 2
            THEN 'Risk'
		WHEN rscore >= 4
		AND fscore >= 3
            THEN 'Loyal'
		ELSE 'Intermediate'
	END AS RFM_Segment
FROM
	rfm_scores
WHERE
	decile_value = 10
ORDER BY
	rfm_score DESC



SELECT
	*
FROM
	vw_customer_segments


 --BQ30-Dealers Performance by Credit Utilisation 
	
CREATE OR replace VIEW vw_dealers_performance AS
WITH dealers_data AS(
SELECT
d.dealer_tier ,
d.dealer_id,
d.credit_limit ,
sum(so.total_amount) AS total_revenue
FROM dealers d
LEFT JOIN sales_orders so ON so.dealer_id = d.dealer_id
WHERE so. dealer_id IS NOT NULL AND so.order_status = 'Delivered'
GROUP BY
d.dealer_tier ,
d.dealer_id,
d.credit_limit
)
SELECT
	dealer_tier,
	round(avg(credit_limit), 2) AS avg_credit,
	round(avg(total_revenue), 2) AS avg_revenue,
	round(avg(total_revenue) * 100.0 / NULLIF(avg(credit_limit), NULL), 2) AS credit_usage
FROM
	dealers_data
GROUP BY
	dealer_tier

SELECT
	*
FROM
	vw_dealers_performance

 
--BQ31-Product & Category Performance 
	
   --product performance
	
create or replace view vw_product_performance as
WITH part_revenue AS (
SELECT
	p.part_id ,
	p.part_name ,
	sum(sol. line_total ) AS revenue
FROM
	parts p
JOIN sales_order_lines sol ON
	sol.part_id = p.part_id
JOIN sales_orders so ON
	so. order_id = sol.order_id
	AND so.order_status = 'Delivered'
GROUP BY
	p.part_id,
	p.part_name
), 
ranked AS (
SELECT
	*,
	sum(revenue)
OVER(ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue,
	sum(revenue) OVER() AS total_revenue,
	ROW_NUMBER() OVER(ORDER BY revenue DESC) AS revenue_rank
FROM
	part_revenue
)
SELECT
	revenue_rank,
	part_id,
	part_name,
	revenue,
	round(running_revenue * 100.0 / NULLIF(total_revenue, 0), 2) AS cumulative_pct
FROM
	ranked
LIMIT 100

select * from vw_product_performance
	
	
   --Category Performance	
	create or replace view vw_category_performance as

create materialized view mvw_category_performance as
with recursive category_tree as (
select
	pc.category_id,
	pc.parent_category_id,
	pc. category_name,
	pc.category_id as parent_id,
	pc. category_name as parent_name
from
	part_categories pc
where
	pc. category_level = 1
union all
select
	pc2.category_id ,
	pc2.parent_category_id,
	pc2.category_name,
	ct.parent_id,
	ct.parent_name
from
	part_categories pc2
join category_tree ct on
	pc2.parent_category_id = ct.category_id
),
line_economy as(
select
	sol.order_id,
	sol.part_id ,
	p.category_id,
	sol. line_total ,
	sol.quantity * ph.cost_price as cost_on_sale
from
	sales_order_lines sol
join parts p on
	p.part_id = sol.part_id
join sales_orders so on
	so. order_id = sol.order_id
	and so.order_status = 'Delivered'
join lateral (
	select
		ph.cost_price
	from
		price_history ph
	where
		ph. part_id = sol.part_id
		and ph. effective_date <= so.order_date
	order by
		ph.effective_date desc
	limit 1
) ph on
	true
)
select
	ct.parent_name as parent_category ,
	ct.category_name as sub_category,
	sum(le. line_total) as revenue,
	sum(le. line_total - le.cost_on_sale ) as profit,
	round(sum(le. line_total - le.cost_on_sale ) * 100.0 / 
	nullif(sum(le. line_total), 0), 2) as profit_margin_pct
from
	category_tree ct
join
line_economy le on
	le.category_id = ct.category_id
group by
	ct.parent_name,
	ct.category_name
order by
	profit_margin_pct desc
	
	
select * from vw_category_performance

select * from mvw_category_performance


--BQ32-Sales Order Funnel Performance 


CREATE OR replace VIEW vw_order_funnel_performance AS
WITH order_stage AS(
SELECT so.order_id,
CASE WHEN so.order_status IN ('Shipped', 'Confirmed', 'Delivered') THEN 1 ELSE 0 END AS confirmed,
CASE WHEN so.order_status IN ('Shipped', 'Delivered') THEN 1 ELSE 0 END AS Shipped,
CASE WHEN so.order_status = 'Delivered' THEN 1 ELSE 0 END AS delivered,
CASE WHEN so.order_status = 'Cancelled' THEN 1 ELSE 0 END AS cancelled
FROM sales_orders so
),
	order_totals AS(
SELECT count(order_id)AS Total_Orders,
sum(confirmed)AS confirmed_orders,
sum(shipped) AS shipped_orders,
sum(delivered) AS delivered_orders,
sum(cancelled) AS cancelled_orders
FROM order_stage
)
SELECT
	stage,
	totals,
	percent
FROM
	order_totals
CROSS JOIN LATERAL (
VALUES
('Total Orders',
total_orders,
100.0),
('Confirmed Orders',
confirmed_orders,
round(confirmed_orders * 100.0 / total_orders, 1)),
('Shipped Orders',
shipped_orders,
round(shipped_orders * 100.0 / total_orders, 1)),
('Delivered Orders',
delivered_orders,
round(delivered_orders * 100.0 / total_orders, 1)),
('Cancelled Orders',
cancelled_orders,
round(cancelled_orders * 100.0 / total_orders, 1))
) AS metrics (stage,
	totals,
	percent)

SELECT
	*
FROM
	vw_order_funnel_performance


--BQ33-Sales Representatives Performance 

CREATE OR replace VIEW vw_sales_rep_performance AS
WITH employees_revenue AS (
SELECT
	e.employee_id,
	e.first_name || ' ' || e.last_name AS emp_name,
	SUM(so.total_amount) AS total_revenue
FROM
	employees e
JOIN sales_orders so
    ON
	so.employee_id = e.employee_id
	AND so.order_status = 'Delivered'
GROUP BY
	e.employee_id,
	emp_name
ORDER BY
	total_revenue DESC
 ), 
 employees_rank AS (
SELECT
	*,
	DENSE_RANK() OVER(ORDER BY total_revenue DESC) AS rnk
FROM
	employees_revenue
)
SELECT
	*
FROM
	employees_rank
WHERE
	rnk <= 10
ORDER BY
	rnk,
	employee_id

SELECT
	*
FROM
	vw_sales_rep_performance
 
	
--BQ34-Regional & Warehouse Performance
	
	
CREATE OR replace VIEW vw_regional_performance AS
WITH regional_orders AS (
SELECT
	w. region,
	sum(so.total_amount) AS total_revenue,
	count(so.order_id) AS total_delivered_orders,
	round(sum(so.total_amount) * 1.0 / NULLIF(count(so.order_id), 0), 2) AS avg_order_value
FROM
	warehouses w
JOIN sales_orders so ON
	so.warehouse_id = w.warehouse_id
	AND so.order_status = 'Delivered'
GROUP BY
	w. region
)
SELECT
	*,
	ROW_NUMBER() OVER(ORDER BY avg_order_value DESC) AS rn
FROM
	regional_orders
LIMIT 3

SELECT
	*
FROM
	vw_regional_performance
	
	
	
	
CREATE OR replace VIEW vw_warehouse AS
WITH warehouse_utilization AS (
SELECT
	w.warehouse_id,
	w.warehouse_name,
	w. capacity_units,
	count(so.order_id) AS total_orders,
	round(count(so.order_id) * 100.0 / w.capacity_units, 2) AS utilization_rate
FROM
	warehouses w
JOIN sales_orders so ON
	so.warehouse_id = w.warehouse_id
	AND so. order_status = 'Delivered'
GROUP BY
	w.warehouse_id ,
	w.warehouse_name,
	w. capacity_units
)
SELECT
	*,
	RANK() OVER(ORDER BY utilization_rate DESC) AS rnk
FROM
	warehouse_utilization

SELECT
	*
FROM
	vw_warehouse