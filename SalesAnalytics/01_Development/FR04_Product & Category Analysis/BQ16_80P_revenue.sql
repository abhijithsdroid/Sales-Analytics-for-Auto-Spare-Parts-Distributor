select * from parts p

select * from sales_order_lines sol

with part_revenue as (
select
	p.part_id ,
	p.part_name ,
	sum(sol. line_total ) as revenue
from
	parts p
join sales_order_lines sol on
	sol.part_id = p.part_id
join sales_orders so on
	so. order_id = sol.order_id
	and so.order_status = 'Delivered'
group by
	p.part_id,
	p.part_name
), 
ranked as (
select *,
sum(revenue)
over(order by revenue desc rows between unbounded preceding and current row) as running_revenue,
sum(revenue ) over() as total_revenue,
row_number() over(order by revenue desc) as revenue_rank
from part_revenue
),
cumulative_revenue as (
select
revenue_rank,
part_id,
part_name,
revenue,
round(running_revenue * 100.0 / nullif(total_revenue, 0), 2) as cumulative_pct
from ranked
)
select
count(*) filter (where cumulative_pct <= 80) as total_parts,
round (count(*) filter (where cumulative_pct <= 80) * 100.0 / count(*), 2) as share_pct
from cumulative_revenue






