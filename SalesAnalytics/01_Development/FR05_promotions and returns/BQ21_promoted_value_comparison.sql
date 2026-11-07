select * from sales_orders so

select
	case
		when so. promotion_id is not null then 'Promoted'
		else 'Not Promoted'
	end as promo_flag,
	count(*) as order_volume,
	round(avg(so.subtotal), 2) as avg_gross_value,
	round (avg(so.discount_amount),
	2) as avg_discount_value,
	round (avg(so.total_amount),
	2) as avg_net_value
from
	sales_orders so
where
	so.order_status = 'Delivered'
group by
	promo_flag