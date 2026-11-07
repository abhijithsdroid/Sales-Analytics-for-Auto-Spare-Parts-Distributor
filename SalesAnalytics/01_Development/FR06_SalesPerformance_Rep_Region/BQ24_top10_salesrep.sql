SELECT * FROM sales_orders so;

SELECT * FROM employees e;

with employees_revenue as (
select
    e.employee_id,
    e.first_name || ' ' || e.last_name AS emp_name,
    SUM(so.total_amount) AS total_revenue
FROM employees e
JOIN sales_orders so
    ON so.employee_id = e.employee_id
    AND so.order_status = 'Delivered'
GROUP BY
    e.employee_id,
    emp_name
ORDER BY
    total_revenue desc
 ), 
 employees_rank as (
select *,
dense_rank() over(order by total_revenue desc) as rnk
from employees_revenue
)
select *
from employees_rank
where rnk <= 10
order by rnk, employee_id

 