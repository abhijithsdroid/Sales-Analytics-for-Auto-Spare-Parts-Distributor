select * from sales_orders so

with total_orders as (
select
	count(so .* ) as delivered_orders
from
	sales_orders so
where
	so. order_status = 'Delivered'
)
select
	pr.promotion_id ,
	pr.promo_code ,
	pr.discount_type ,
	pr.discount_value,
	count (so. order_id) as redemption_count,
round (count (so.order_id) * 100.0 / nullif(tot.delivered_orders, 0), 2) as redemption_rate,
round (sum(so.discount_amount) * 100.0 / nullif(sum(so.subtotal), 0), 2) as avg_discount_depth
from
	promotions pr
left join
sales_orders so on
	pr.promotion_id = so.promotion_id
	and so.order_status = 'Delivered'
cross join
total_orders tot
group by
	pr.promotion_id ,
	pr.promo_code,
	pr.discount_type ,
	pr.discount_value,
	tot.delivered_orders
order by
redemption_rate desc,
avg_discount_depth asc

-- 1. High Redemption Rate, Low Discount Depth => High Preferred
--* 2. High Redemption Rate, High Discount Depth => 2nd
--* 3. Low Redemption rate, low discount depth => 3rd
--* 4. Low Redemption rate, high discount dept => 4th
--*