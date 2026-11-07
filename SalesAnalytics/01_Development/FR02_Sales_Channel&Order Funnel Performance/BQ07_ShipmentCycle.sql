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
