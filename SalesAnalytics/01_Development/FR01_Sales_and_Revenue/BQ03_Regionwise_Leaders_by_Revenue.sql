
select *
from sales_orders so 

select *
from dealers d 

select *
from retail_customers rc

with regional_data as(
select 
so.channel,so.total_amount,coalesce(d.region,rc.region)as region
from sales_orders so left join 
dealers d on d.dealer_id =so.dealer_id 
left join retail_customers rc on rc.customer_id =so.customer_id 
)
select coalesce(region,'Grand Total') as region,
sum(total_amount)filter(where channel='RETAIL')as retail,
sum(total_amount)filter(where channel='ONLINE')as online,
sum(total_amount)filter(where channel='DEALER')as dealer,
sum(total_amount)as total_revenue
from regional_data
group by rollup(region)
order by grouping(region),total_revenue desc
