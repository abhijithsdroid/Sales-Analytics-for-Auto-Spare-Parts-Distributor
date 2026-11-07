
select * from sales_orders so

-- Calculate Average Order Value & Volume By Channel
select
channel,
avg(so.total_amount) as avg_value,
count(so.order_id)
from sales_orders so 
where so.order_status ='Delivered'
group by so.channel 