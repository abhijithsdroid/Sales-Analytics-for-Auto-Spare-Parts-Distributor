select * from dealers d

select * from sales_orders so

with dealers_data as(
select
d.dealer_tier ,
d.dealer_id,
d.credit_limit ,
sum(so.total_amount ) as total_revenue
from dealers d
left join sales_orders so on so.dealer_id = d.dealer_id
where so. dealer_id is not null and so.order_status ='Delivered'
group by
d.dealer_tier ,
d.dealer_id,
d.credit_limit
)
select
dealer_tier,
round(avg(credit_limit), 2) as avg_credit,
round(avg(total_revenue ), 2) as avg_revenue,
round(avg(total_revenue ) * 100.0 / nullif(avg(credit_limit), null), 2) as credit_usage
from
dealers_data
group by
dealer_tier

