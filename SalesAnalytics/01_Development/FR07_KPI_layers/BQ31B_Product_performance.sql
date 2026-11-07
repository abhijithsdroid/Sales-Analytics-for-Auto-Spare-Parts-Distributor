
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