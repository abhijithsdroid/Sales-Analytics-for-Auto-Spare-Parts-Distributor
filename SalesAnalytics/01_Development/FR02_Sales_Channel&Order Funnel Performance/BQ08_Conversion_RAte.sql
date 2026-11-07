select * from sales_orders so

select distinct order_status from sales_orders so

select
	channel,
	count(*) as total_orders,
	count(*) filter
(
	where order_status in ('Confirmed', 'Shipped', 'Delivered')) as converted_orders,
	round (count(*) filter
(
	where order_status in ('Confirmed', 'Shipped', 'Delivered')) * 100.0 / count(*), 2) as conversion_rate,
	count(*) filter
(
	where order_status = 'Cancelled') as cancelled_orders,
	round (count(*) filter
(
	where order_status = 'Cancelled') * 100.0 / count(*),
	2) as cancelled_rate
from
	sales_orders so
group by
	channel

