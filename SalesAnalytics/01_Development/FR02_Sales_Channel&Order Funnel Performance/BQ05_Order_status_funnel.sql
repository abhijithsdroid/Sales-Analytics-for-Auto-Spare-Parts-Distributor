select
	*
from
	sales_orders so 

with order_stage as(
select so.order_id,
case when so.order_status in ('Shipped', 'Confirmed', 'Delivered') then 1 else 0 end as confirmed,
case when so.order_status in ('Shipped', 'Delivered') then 1 else 0 end as Shipped,
case when so.order_status = 'Delivered' then 1 else 0 end as delivered,
case when so.order_status = 'Cancelled' then 1 else 0 end as cancelled
from sales_orders so
),
	order_totals as(
select count(order_id)as Total_Orders,
sum(confirmed)as confirmed_orders,
sum(shipped) as shipped_orders,
sum(delivered) as delivered_orders,
sum(cancelled) as cancelled_orders
from order_stage
)
select
	stage,
	totals,
	percent
from
	order_totals
cross join lateral (
values
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
) as metrics (stage,
	totals,
	percent)
