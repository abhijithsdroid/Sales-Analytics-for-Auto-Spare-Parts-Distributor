
create or replace view vw_monthly_sales_performance as
with month_spine as(
SELECT
    GENERATE_SERIES(
        (SELECT MIN(order_date)::date FROM sales_orders),
        (SELECT MAX(order_date)::date FROM sales_orders),
        INTERVAL '1 month'
    )::date as month_start
),
revenue_data as(
select 
date_trunc('month',so.order_date )::date as month_start,
sum(so.total_amount ) as revenue
from sales_orders so 
where so.order_status ='Delivered'
group by month_start 
order by month_start 
)
select ms.month_start,rd.revenue,
coalesce(round((rd.revenue -lag(rd.revenue)over(order by ms.month_start asc))*100.0/
lag(rd.revenue)over(order by ms.month_start asc),2),0) as MoM_growth,
coalesce(round((rd.revenue -lag(rd.revenue,12)over(order by ms.month_start asc))*100.0/
lag(rd.revenue,12)over(order by ms.month_start asc),2),0) as YoY_growth
from month_spine ms 
left join  revenue_data rd on ms.month_start=rd.month_start



select * from vw_monthly_sales_performance vmsp