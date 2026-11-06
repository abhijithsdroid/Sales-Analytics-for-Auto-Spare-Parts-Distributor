select * from warehouses w

select * from sales_orders so

select * from "returns" r

select distinct status from "returns" r

with warehouse_returns as (
select
	w.warehouse_id,
	w.warehouse_name,
	so.order_id,
	r.return_id,
	case
		when r.status in ('Refunded', 'Approved') then true
		else false
	end as return_status
from
	warehouses w
join
sales_orders so on
	so.warehouse_id = w.warehouse_id
	and so. order_status = 'Delivered'
left join
"returns" r on
	r.order_id = so.order_id
)
select
	warehouse_id ,
	warehouse_name,
	count (order_id) as delivered_orders,
	count(return_id) filter (
	where return_status ) as returned_orders,
	round(count(return_id) filter (where return_status ) * 100.0 /
nullif(count(order_id), 0), 2) as return_rate
from
	warehouse_returns
group by
	warehouse_id,
	warehouse_name
order by
	return_rate desc
