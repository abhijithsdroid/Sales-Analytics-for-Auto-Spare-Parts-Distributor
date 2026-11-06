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


