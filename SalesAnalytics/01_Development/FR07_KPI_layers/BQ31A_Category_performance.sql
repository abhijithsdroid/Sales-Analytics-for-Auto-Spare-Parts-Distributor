



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