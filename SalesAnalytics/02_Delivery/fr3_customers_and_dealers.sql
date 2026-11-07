 --FR-3    Customer & Dealer Sales Analytics
 
 --Turn the two customer masters — dealers and retail customers — into a segmentation the business can actually act on. 
 
 
 --BQ09-RFM segments for retail customers — who sits in the top decile? 
 
 WITH latest_data AS (
    SELECT
        MAX(so.order_date)::DATE AS latest_business_date
    FROM sales_orders so
),
customer_data AS (
    SELECT
        so.customer_id,
        MAX(so.order_date)::DATE AS last_order_date,
        COUNT(*) AS frequency,
        SUM(so.total_amount) AS monetary
    FROM sales_orders so
    WHERE so.customer_id IS NOT NULL
    GROUP BY so.customer_id
),
rfm_values AS (
    SELECT
        cd.customer_id,
        ld.latest_business_date - cd.last_order_date AS recency,
        cd.frequency,
        cd.monetary
    FROM customer_data cd
    CROSS JOIN latest_data ld
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency DESC) AS rscore,
        NTILE(5) OVER (ORDER BY frequency ASC) AS fscore,
        NTILE(5) OVER (ORDER BY monetary ASC) AS mscore,
        NTILE(10) OVER (ORDER BY monetary ASC) AS decile_value
    FROM rfm_values
)
SELECT
    customer_id,
    rscore + fscore + mscore AS rfm_score,
    CASE
        WHEN rscore = 5 AND fscore = 5 AND mscore = 5
            THEN 'Champion'
        WHEN rscore = 1 AND fscore = 1
            THEN 'Lost'
        WHEN rscore <= 2 AND fscore <= 2
            THEN 'Risk'
        WHEN rscore >= 4 AND fscore >= 3
            THEN 'Loyal'
        ELSE 'Intermediate'
    END AS RFM_Segment
FROM rfm_scores 
where decile_value = 10
order by
rfm_score DESC


--BQ10-An approximate CLV per customer and per segment.



--Saving Customer segments

WITH latest_data AS (
    SELECT
        MAX(so.order_date)::DATE AS latest_business_date
    FROM sales_orders so
),
customer_data AS (
    SELECT
        so.customer_id,
        MAX(so.order_date)::DATE AS last_order_date,
        COUNT(*) AS frequency,
        SUM(so.total_amount) AS monetary
    FROM sales_orders so
    WHERE so.customer_id IS NOT NULL
    GROUP BY so.customer_id
),
rfm_values AS (
    SELECT
        cd.customer_id,
        ld.latest_business_date - cd.last_order_date AS recency,
        cd.frequency,
        cd.monetary
    FROM customer_data cd
    CROSS JOIN latest_data ld
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency DESC) AS rscore,
        NTILE(5) OVER (ORDER BY frequency ASC) AS fscore,
        NTILE(5) OVER (ORDER BY monetary ASC) AS mscore,
        NTILE(10) OVER (ORDER BY monetary ASC) AS decile_value
    FROM rfm_values
)
SELECT
    customer_id,
    rscore + fscore + mscore AS rfm_score,
    CASE
        WHEN rscore = 5 AND fscore = 5 AND mscore = 5
            THEN 'Champion'
        WHEN rscore = 1 AND fscore = 1
            THEN 'Lost'
        WHEN rscore <= 2 AND fscore <= 2
            THEN 'Risk'
        WHEN rscore >= 4 AND fscore >= 3
            THEN 'Loyal'
        ELSE 'Intermediate'
    END AS RFM_Segment
FROM rfm_scores 




WITH customer_orders AS (
SELECT
	so.customer_id,
	sum(so.total_amount) AS total_revenue,
	count(*) AS total_orders,
	(max(order_date)::date - min(order_date) :: date ) * 1.0 / 100 AS life_span
FROM
	sales_orders so
GROUP BY
	so. customer_id
),
clv_values AS (
SELECT
	customer_id,
	total_revenue * 1.0 / NULLIF(total_orders, 0) AS AoV,
	total_orders * 1.0 / NULLIF(life_span , 0) AS purchase_frequency,
	life_span
FROM
	customer_orders)
SELECT
	customer_id,
	aov * purchase_frequency * life_span AS clv
FROM
	clv_values
)


SELECT
	cs.rfm_segment,
	sum(cc.clv) AS total_clv,
	avg(cc. clv) AS avg_clv
FROM
	customer_segment cs
LEFT JOIN customer_clv cc ON
	cc. customer_id = cs. customer_id
GROUP BY
	cs. rfm_segment
	
	
--BQ11-Cohort retention by signup month — what share of a cohort is still ordering N months on?
	
	
WITH cohort_months AS (
SELECT
		generate_series(
(SELECT min(signup_date) FROM retail_customers),
(SELECT max(order_date) :: date FROM sales_orders),
INTERVAL '1 month'
) :: date AS cohort_month,
		(
	SELECT
			max(order_date) :: date
	FROM
			sales_orders) AS last_order_month),
	signup_months AS(
SELECT *,
(EXTRACT('year' FROM last_order_month) - EXTRACT('year' FROM cohort_month)) * 12 +
(EXTRACT ('month' FROM last_order_month) - EXTRACT ('month' FROM cohort_month)) AS signup_since_months
FROM cohort_months
),
	signup_month_table AS(
SELECT *,
generate_series(1, signup_since_months) AS signup_since
FROM signup_months
),
	cohort_customers AS (
SELECT
		smt. cohort_month,
		smt.signup_since,
		rc. customer_id
FROM
		signup_month_table smt
LEFT JOIN
retail_customers rc ON
		smt. cohort_month = date_trunc('month', rc.signup_date)
),
	total_cohort_customers AS (
SELECT
		*,
		count(customer_id) OVER(PARTITION BY cohort_month, signup_since) AS cohort_customers
FROM
		cohort_customers),
	customer_orders AS(
SELECT
tcc .* ,
count(so.*) AS total_orders
FROM
total_cohort_customers tcc
LEFT JOIN
sales_orders so ON
date_trunc('month', so. order_date) = tcc.cohort_month + INTERVAL '1 month' * (signup_since - 1) AND
so. customer_id = tcc.customer_id
GROUP BY tcc.cohort_month, tcc.signup_since, tcc.customer_id, tcc.cohort_customers),
cohort_retention AS(
SELECT
	cohort_month,
	signup_since,
	cohort_customers,
	count(customer_id) AS retained_customers
FROM
	customer_orders
WHERE
	total_orders != 0
GROUP BY
	cohort_month,
	signup_since,
	cohort_customers
ORDER BY
cohort_month,
signup_since,
cohort_customers
)
SELECT
	cohort_month,
	signup_since,
	round(retained_customers * 100.0 / NULLIF(cohort_customers, 0), 2) AS retained_pct
FROM
	cohort_retention
	
	
	
--BQ12--How does dealer tier performance differ in terms of average credit limit, average delivered revenue per dealer, and credit utilisation? 

WITH dealers_data AS(
SELECT
d.dealer_tier ,
d.dealer_id,
d.credit_limit ,
sum(so.total_amount) AS total_revenue
FROM dealers d
LEFT JOIN sales_orders so ON so.dealer_id = d.dealer_id
WHERE so. dealer_id IS NOT NULL AND so.order_status = 'Delivered'
GROUP BY
d.dealer_tier ,
d.dealer_id,
d.credit_limit
)
SELECT
	dealer_tier,
	round(avg(credit_limit), 2) AS avg_credit,
	round(avg(total_revenue), 2) AS avg_revenue,
	round(avg(total_revenue) * 100.0 / NULLIF(avg(credit_limit), NULL), 2) AS credit_usage
FROM
	dealers_data
GROUP BY
	dealer_tier
	
	
--BQ13-Which acquisition_channel produces the highest-value customers? 
	
select
	rc.acquisition_channel,
	count(distinct rc.customer_id ) as total_customers,
	sum(so.total_amount) filter (
	where order_status = 'Delivered') as total_revenue,
	round(sum(so.total_amount) filter (where order_status = 'Delivered') * 1.0 /
nullif(count(distinct rc.customer_id ), 0), 2) as revenue_per_customer
from
	retail_customers rc
left join
sales_orders so on
	so. customer_id = rc.customer_id
group by
	rc. acquisition_channel
order by
	revenue_per_customer desc