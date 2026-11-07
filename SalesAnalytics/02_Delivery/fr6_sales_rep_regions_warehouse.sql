--FR-6    Sales Performance — Representatives, Regions & Warehouses 

--Rank internal sales performance by employee and warehouse to identify who is driving — or dragging on — revenue.


--BQ24--List the top 10 sales representatives ranked by realised revenue. 

WITH employees_revenue AS (
SELECT
	e.employee_id,
	e.first_name || ' ' || e.last_name AS emp_name,
	SUM(so.total_amount) AS total_revenue
FROM
	employees e
JOIN sales_orders so
    ON
	so.employee_id = e.employee_id
	AND so.order_status = 'Delivered'
GROUP BY
	e.employee_id,
	emp_name
ORDER BY
	total_revenue DESC
 ), 
 employees_rank AS (
SELECT
	*,
	DENSE_RANK() OVER(ORDER BY total_revenue DESC) AS rnk
FROM
	employees_revenue
)
SELECT
	*
FROM
	employees_rank
WHERE
	rnk <= 10
ORDER BY
	rnk,
	employee_id
	
	
--BQ25-Rank the top 3 regions based on average order value.
	
with regional_orders as (
select
	w. region,
	sum(so.total_amount) as total_revenue,
	count(so.order_id) as total_delivered_orders,
	round(sum(so.total_amount) * 1.0 / nullif(count(so.order_id), 0), 2) as avg_order_value
from
	warehouses w
join sales_orders so on
	so.warehouse_id = w.warehouse_id
	and so.order_status = 'Delivered'
group by
	w. region
)
select
	*,
	row_number() over(order by avg_order_value desc) as rn
from
	regional_orders
limit 3


--BQ26--List all warehouses ranked by utilisation rate (highest first). 

with warehouse_utilization as (
select
	w.warehouse_id,
	w.warehouse_name,
	w. capacity_units,
	count(so.order_id) as total_orders,
	round(count(so.order_id) * 100.0 / w.capacity_units, 2) as utilization_rate
from
	warehouses w
join sales_orders so on
	so.warehouse_id = w.warehouse_id
	and so. order_status = 'Delivered'
group by
	w.warehouse_id ,
	w.warehouse_name,
	w. capacity_units
)
select *,
rank() over(order by utilization_rate desc) as rnk
from warehouse_utilization


--BQ27--Find and list warehouses by return rate.

with warehouse_returns as (
select
	w.warehouse_id,
	w.warehouse_name,
	so.order_id,
	r.return_id,
	case
		when r.status in ('Refunded', 'Approved') then true
		else false
	end as return_status
from
	warehouses w
join
sales_orders so on
	so.warehouse_id = w.warehouse_id
	and so. order_status = 'Delivered'
left join
"returns" r on
	r.order_id = so.order_id
)
select
	warehouse_id ,
	warehouse_name,
	count (order_id) as delivered_orders,
	count(return_id) filter (
	where return_status ) as returned_orders,
	round(count(return_id) filter (where return_status ) * 100.0 /
nullif(count(order_id), 0), 2) as return_rate
from
	warehouse_returns
group by
	warehouse_id,
	warehouse_name
order by
	return_rate desc
