select * from warehouses w

select * from sales_orders so

with warehouse_utilization as (
select
	w.warehouse_id,
	w.warehouse_name,
	w. capacity_units,
	count(so.order_id) as total_orders,
	round(count(so.order_id) * 100.0 / w.capacity_units, 2) as utilization_rate
from
	warehouses w
join sales_orders so on
	so.warehouse_id = w.warehouse_id
	and so. order_status = 'Delivered'
group by
	w.warehouse_id ,
	w.warehouse_name,
	w. capacity_units
)
select *,
rank() over(order by utilization_rate desc) as rnk
from warehouse_utilization