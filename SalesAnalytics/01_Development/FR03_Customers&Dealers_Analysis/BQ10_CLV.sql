

select * from sales_orders so 

./*
* Customer LifeTime Value (clv) = AoV * Purchase Freqency * Life Span
* Average Order Value (AoV) = Total Revenue / Total Orders
* Purchase Frequency = Total Orders / Life Span
* Life Span = Last Order Date - First Order Date (Range)
*/*/

--Saving Customer segments

create view customer_segment as
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


select * from customer_segment cs 




create view customer_clv as
with customer_orders as (
select
so.customer_id,
sum(so.total_amount ) as total_revenue,
count(*) as total_orders,
(max(order_date)::date - min(order_date) :: date ) * 1.0/100 as life_span
from
sales_orders so
group by
so. customer_id
), clv_values as (
select
customer_id,
total_revenue * 1.0 / nullif(total_orders, 0) as AoV,
total_orders * 1.0 / nullif(life_span , 0) as purchase_frequency,
life_span
from customer_orders)
select
customer_id,
aov * purchase_frequency *life_span as clv
from clv_values
)


-- CLV per Segment
select
cs.rfm_segment,
sum(cc.clv ) as total_clv,
avg(cc. clv) as avg_clv
from customer_segment cs
left join customer_clv cc on cc. customer_id = cs. customer_id
group by cs. rfm_segment