select * from sales_orders so

select * from retail_customers rc

select * from employees e

select * from warehouses w

select * from sales_orders so
where so.warehouse_id is not null

with regional_orders as (
select
	w. region,
	sum(so.total_amount) as total_revenue,
	count(so.order_id) as total_delivered_orders,
	round(sum(so.total_amount) * 1.0 / nullif(count(so.order_id), 0), 2) as avg_order_value
from
	warehouses w
join sales_orders so on
	so.warehouse_id = w.warehouse_id
	and so.order_status = 'Delivered'
group by
	w. region
)
select
	*,
	row_number() over(order by avg_order_value desc) as rn
from
	regional_orders
limit 3

