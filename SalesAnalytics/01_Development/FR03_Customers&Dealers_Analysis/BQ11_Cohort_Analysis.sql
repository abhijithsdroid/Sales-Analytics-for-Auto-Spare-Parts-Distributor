select
	*
from
	retail_customers rc

select
	min(signup_date)
from
	retail_customers rc
select
	max(order_date)
from
	sales_orders so
	
	

with cohort_months as (
	select
		generate_series(
(select min(signup_date) from retail_customers),
(select max(order_date) :: date from sales_orders),
interval '1 month'
) :: date as cohort_month,
		(
		select
			max(order_date) :: date
		from
			sales_orders) as last_order_month),
	signup_months as(
select *,
(extract('year' from last_order_month) - extract('year' from cohort_month)) * 12 +
(extract ('month' from last_order_month) - extract ('month' from cohort_month)) as signup_since_months
from cohort_months
),
	signup_month_table as(
select *,
generate_series(1, signup_since_months) as signup_since
from signup_months
),
	cohort_customers as (
	select
		smt. cohort_month,
		smt.signup_since,
		rc. customer_id
	from
		signup_month_table smt
	left join
retail_customers rc on
		smt. cohort_month = date_trunc('month', rc.signup_date)
),
	total_cohort_customers as (
	select
		*,
		count(customer_id) over(partition by cohort_month, signup_since) as cohort_customers
	from
		cohort_customers),
	customer_orders as(
select
tcc .* ,
count(so.*) as total_orders
from
total_cohort_customers tcc
left join
sales_orders so on
date_trunc('month', so. order_date) = tcc.cohort_month + interval '1 month' * (signup_since - 1) and
so. customer_id = tcc.customer_id
group by tcc.cohort_month, tcc.signup_since, tcc.customer_id, tcc.cohort_customers),
cohort_retention as(
select
	cohort_month,
	signup_since,
	cohort_customers,
	count(customer_id) as retained_customers
from
	customer_orders
where
	total_orders != 0
group by
	cohort_month,
	signup_since,
	cohort_customers
order by
cohort_month,
signup_since,
cohort_customers
)
select
cohort_month,
signup_since,
round(retained_customers * 100.0 / nullif(cohort_customers, 0), 2) as retained_pct
from cohort_retention