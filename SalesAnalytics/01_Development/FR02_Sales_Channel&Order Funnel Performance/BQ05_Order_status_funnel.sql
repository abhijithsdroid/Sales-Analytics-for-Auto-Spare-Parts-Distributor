select * from sales_orders so 

with order_stage as(
select so.order_id,
case when so.order_status in ('Shipped','Confirmed','Delivered') then 1 else 0 end as confirmed,
case when so.order_status in ('Shipped','Delivered') then 1 else 0 end as Shipped,
case when so.order_status ='Delivered' then 1 else 0 end as delivered,
case when so.order_status ='Cancelled' then 1 else 0 end as cancelled
from sales_orders so
),
order_totals as(
select count(order_id)as TotalOrders,
sum(confirmed)as confirmed_orders,
sum(shipped) as shipped_orders,
sum(delivered) as delivered_orders
from order_stage
)
select *
from order_totals
cross join(values)