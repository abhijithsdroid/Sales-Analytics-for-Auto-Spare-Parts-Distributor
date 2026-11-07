select * from price_history ph

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

