 --FR-4    Product & Category Sales Performance
 --Identify what sells, what’s actually profitable once cost is accounted for, and how pricing decisions have moved either.
 
 
 
 --BQ14- Analyse revenue and gross margin by category and sub-category using the part category hierarchy.
 
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
	profit_margin_pct DESC
	
	
--BQ15- Rank parts by revenue and calculate their cumulative contribution to total revenue, showing the top 100 parts by revenue. 
	
	
	
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





--BQ16-Identify the number and percentage of parts that collectively generate 80% of total revenue. 

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
),
cumulative_revenue AS (
SELECT
	revenue_rank,
	part_id,
	part_name,
	revenue,
	round(running_revenue * 100.0 / NULLIF(total_revenue, 0), 2) AS cumulative_pct
FROM
	ranked
)
SELECT
	count(*) FILTER (
	WHERE cumulative_pct <= 80) AS total_parts,
	round (count(*) FILTER (
	WHERE cumulative_pct <= 80) * 100.0 / count(*),
	2) AS share_pct
FROM
	cumulative_revenue
	
	
--BQ17-Compare OEM vs. non-OEM manufacturers by distinct parts sold, revenue, gross margin, and margin percentage.
	
	
with line_economy as (
select
	sol.order_id ,
	sol.part_id ,
	p.category_id,
	p.manufacturer_id,
	sol.line_total ,
	sol.quantity * ph.cost_price as cost_on_sale
from
	sales_order_lines sol
join parts p on
	p.part_id = sol.part_id
join sales_orders so on
	so. order_id = sol.order_id
	and so. order_status = 'Delivered'
join lateral (
	select
		ph.cost_price
	from
		price_history ph
	where
		ph.part_id = sol.part_id
		and ph.effective_date <= so.order_date
	order by
		ph.effective_date desc
	limit 1
) ph on
	true
),
oem_table as (
select
	le .* ,
	case
		when m. is_oem = true then 'OEM'
		else 'Non-OEM'
	end as oem_category
from
	line_economy le
join manufacturers m on
	m.manufacturer_id = le.manufacturer_id
)
select
	oem_category,
	count(distinct part_id ) as total_parts,
	sum(line_total) as revenue,
	sum(line_total - cost_on_sale) as gross_margin,
	round(sum(line_total - cost_on_sale) * 100.0 / nullif(sum(line_total), 0), 2) as margin_pct
from
	oem_table
group by
	oem_category
	
--BQ18-Analyse whether list price changes are associated with shifts in unit volume by comparing sales volume 30 days before and after each price change.
	
	
with previous_price_table as (
select
	ph.part_id,
	ph.effective_date as change_date ,
	ph. list_price as current_price,
	lag(ph. list_price ) over(partition by part_id order by ph.effective_date) as previous_price
from
	price_history ph
),
price_change_table as (
select
	*
from
	previous_price_table
where
	previous_price is not null
	and previous_price <> current_price
)
select
	pct .* ,
	round((current_price - previous_price) * 100.0 / previous_price, 2)as price_change_pct,
	coalesce(sum(sol.quantity) filter(
where so. order_date < pct.change_date and
so. order_date >= pct. change_date - interval '30 days'
), 0) as volume_before_30days,
	coalesce(sum(sol.quantity) filter(
where so. order_date > pct. change_date and
so. order_date <= pct.change_date + interval '30 days'
), 0) as volume_after_30days
from
	price_change_table pct
join sales_order_lines sol on
	sol.part_id = pct.part_id
join sales_orders so on
	so. order_id = sol.order_id
	and so.order_status = 'Delivered'
group by
	pct.part_id ,
	pct.change_date,
	pct.current_price ,
	pct.previous_price
order by
	pct.part_id ,
	pct.change_date
	
	
--BQ19- Identify the top 25 vehicle makes and models by revenue generated from compatible parts. 
	
	
select
	vmk.make_name,
	vm.model_name,
	sum(sol.line_total) as revenue
from
	sales_order_lines sol
join sales_orders so on
	so. order_id = sol.order_id
	and so.order_status = 'Delivered'
join part_vehicle_compatibility pvc on
	pvc.part_id = sol.part_id
join vehicle_model_years vmy on
	vmy.model_year_id = pvc.model_year_id
join vehicle_models vm on
	vm.model_id = vmy.model_id
join vehicle_makes vmk on
	vmk.make_id = vm.make_id
group by
	vmk. make_name ,
	vm.model_name
order by
	revenue desc
limit 25
