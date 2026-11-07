

create or replace view vw_customer_segments as
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
rfm_score desc



select * from vw_customer_segments