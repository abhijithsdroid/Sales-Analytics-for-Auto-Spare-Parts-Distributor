-- FR-2    Sales Channel & Order Funnel Performance 
--Compare how Dealer, Retail and Online actually perform, and trace the order lifecycle from placement to 
--delivery or cancellation. 


--BQ05-Order-status funnel — what share of orders reach Confirmed, Shipped, 
--and Delivered, and what share end in Cancelled? 

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
	
	
--BQ06- Average order-to-ship and order-to-delivery cycle time by channel, from shipments.
	
WITH shipping_cycle AS(
SELECT
so.order_id ,
so. channel,
so.order_date,
s.ship_date ,
s.ship_date - so.order_date :: date AS shipping_days
FROM sales_orders so
LEFT JOIN shipments s ON s. order_id = so.order_id
WHERE s. ship_date IS NOT NULL
ORDER BY shipping_days DESC
),
delivery_cycle AS (
SELECT
	so.order_id ,
	so. channel ,
	so.order_date,
	s.delivery_date,
	s.delivery_date- so.order_date::date AS delivery_days
FROM
	sales_orders so
LEFT JOIN shipments s ON
	s.order_id = so.order_id
WHERE
	s.delivery_date IS NOT NULL
ORDER BY
	delivery_days DESC
)
SELECT
	sc.channel,
	round(avg(sc.shipping_days), 2) AS avg_shipping_cycle,
	percentile_cont(0.5) WITHIN GROUP (
ORDER BY
	shipping_days) AS median_shipping_cycle,
	round(avg(dc.delivery_days), 2) AS avg_delivery_cycle,
	percentile_cont(0.5) WITHIN GROUP (
ORDER BY
	delivery_days) AS median_delivery_cycle
FROM
	shipping_cycle sc
LEFT JOIN
delivery_cycle dc ON
	sc.order_id = dc.order_id
GROUP BY
	sc. channel
	
	
	
	
--BQ07-Shipment status distribution (Delayed / Returned) and its relationship to channel and region. 
	
	
with shipping_table as (
select
	so. channel,
	coalesce(d.region , rc.region ) as region,
	s. shipment_status
from
	sales_orders so
left join dealers d on
	d.dealer_id = so.dealer_id
left join retail_customers rc on
	rc. customer_id = so.customer_id
left join shipments s on
	s. order_id = so.order_id
where
	order_status in ('Delivered', 'Shipped')
)
select
	channel,
	region,
	count(*) as qualified_orders,
	count(*) filter (
	where shipment_status = 'Delayed') as delayed_orders,
	round(count(*) filter (where shipment_status = 'Delayed') * 100.0 / count(*), 2) as delayed_pct,
	count(*) filter (
	where shipment_status = 'Returned') as returned_orders,
	round(count(*) filter (where shipment_status = 'Returned') * 100.0 / count(*) , 2) as returned_pct
from
	shipping_table
group by
	channel,
	region
	
	
--BQ08-Channel-wise order conversion & cancellation rate. 

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

