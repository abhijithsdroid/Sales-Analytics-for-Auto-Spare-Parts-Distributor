./*
* Cancelled_Pct = (cancelled_amount) * 100.0 / (Booked_amount + Cancelled Amount)
* Discount_Pct = Discount Amount * 100.0 / Gross Amount
* */
select * from sales_orders so 


with calculated_table as(
select 
date_trunc('month',so.order_date)::date as month_start,
sum(so.total_amount)filter(where so.order_status='Delivered' )as booked_revenue,
sum(so.total_amount)filter(where so.order_status='Cancelled' )as cancelled_revenue,
sum(so.discount_amount)filter(where so.order_status='Delivered' )as discounted_amount,
sum(so.subtotal)filter(where so.order_status='Delivered' )as gross_amount
from 
sales_orders so 
group by month_start 
)
select month_start,
round((cancelled_revenue*100.0)/
nullif((booked_revenue+cancelled_revenue),0),2)as cancelled_pct,
round((discounted_amount*100.0)/nullif(gross_amount,0),2) as discount_pct
from calculated_table 
order by month_start