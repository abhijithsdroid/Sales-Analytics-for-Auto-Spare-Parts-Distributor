select
	rc.acquisition_channel,
	count(distinct rc.customer_id ) as total_customers,
	sum(so.total_amount) filter (
	where order_status = 'Delivered') as total_revenue,
	round(sum(so.total_amount) filter (where order_status = 'Delivered') * 1.0 /
nullif(count(distinct rc.customer_id ), 0), 2) as revenue_per_customer
from
	retail_customers rc
left join
sales_orders so on
	so. customer_id = rc.customer_id
group by
	rc. acquisition_channel
order by
	revenue_per_customer desc