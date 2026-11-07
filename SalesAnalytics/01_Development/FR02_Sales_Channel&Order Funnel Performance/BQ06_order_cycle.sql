 -- Step 1 - Calculate Shipping Cycle
select
so.order_id ,
so. channel ,
so.order_date,
s.ship_date ,
s.ship_date - so.order_date :: date as shipping_days
from sales_orders so
left join shipments s on s.order_id = so.order_id
where s. ship_date is not null
order by shipping_days desc


 -- Step 2 - Calculate Delivery Cycle
select
so.order_id ,
so. channel ,
so.order_date,
s.delivery_date,
s.delivery_date - so.order_date :: date as delivery_days
from sales_orders so
left join shipments s on s. order_id = so.order_id
where s. delivery_date is not null
order by delivery_days desc

.
 -- Step 3 - Combining shipping & Delivery cycles and Calculate Avg/Median


with shipping_cycle as(
select
so.order_id ,
so. channel,
so.order_date,
s.ship_date ,
s.ship_date - so.order_date :: date as shipping_days
from sales_orders so
left join shipments s on s. order_id = so.order_id
where s. ship_date is not null
order by shipping_days desc
),
delivery_cycle as (
select
	so.order_id ,
	so. channel ,
	so.order_date,
	s.delivery_date,
	s.delivery_date- so.order_date::date as delivery_days
from
	sales_orders so
left join shipments s on
	s.order_id = so.order_id
where
	s.delivery_date is not null
order by
	delivery_days desc
)
select
	sc.channel,
	round(avg(sc.shipping_days), 2) as avg_shipping_cycle,
	percentile_cont(0.5) within group (
	order by shipping_days) as median_shipping_cycle,
	round(avg(dc.delivery_days), 2) as avg_delivery_cycle,
	percentile_cont(0.5) within group (
	order by delivery_days) as median_delivery_cycle
from
	shipping_cycle sc
left join
delivery_cycle dc on
	sc.order_id = dc.order_id
group by
	sc. channel

