-- FR-5    Promotions & Returns Impact on Sales 

--Quantify what promotional discounting is actually buying the business in incremental sales, and how much return activity is eroding net revenue. 


--BQ20--Promo-code redemption rate and average discount depth (discount_amount subtotal) by promotion.

with total_orders as (
select
	count(so .* ) as delivered_orders
from
	sales_orders so
where
	so. order_status = 'Delivered'
)
select
	pr.promotion_id ,
	pr.promo_code ,
	pr.discount_type ,
	pr.discount_value,
	count (so. order_id) as redemption_count,
round (count (so.order_id) * 100.0 / nullif(tot.delivered_orders, 0), 2) as redemption_rate,
round (sum(so.discount_amount) * 100.0 / nullif(sum(so.subtotal), 0), 2) as avg_discount_depth
from
	promotions pr
left join
sales_orders so on
	pr.promotion_id = so.promotion_id
	and so.order_status = 'Delivered'
cross join
total_orders tot
group by
	pr.promotion_id ,
	pr.promo_code,
	pr.discount_type ,
	pr.discount_value,
	tot.delivered_orders
order by
redemption_rate desc,
avg_discount_depth ASC


--BQ21-Does promoted order value / volume outperform non-promoted, net of the discount given?

select
	case
		when so. promotion_id is not null then 'Promoted'
		else 'Not Promoted'
	end as promo_flag,
	count(*) as order_volume,
	round(avg(so.subtotal), 2) as avg_gross_value,
	round (avg(so.discount_amount),
	2) as avg_discount_value,
	round (avg(so.total_amount),
	2) as avg_net_value
from
	sales_orders so
where
	so.order_status = 'Delivered'
group by
	promo_flag
	
	
--BQ22- Return rate by category and channel, and its dollar impact on net sales (refund_amount). 
	
	WITH return_orders AS (
    SELECT
        sol.*,
        so.channel,
        pc.category_name,
        CASE
            WHEN r.status IN ('Approved', 'Refunded') THEN TRUE
            ELSE FALSE
        END AS refund_status,
        CASE
            WHEN r.status IN ('Approved', 'Refunded') THEN rl.refund_amount
            ELSE 0
        END AS refund_amount
    FROM sales_order_lines sol
    JOIN sales_orders so
        ON so.order_id = sol.order_id
        AND so.order_status = 'Delivered'
    JOIN parts p
        ON p.part_id = sol.part_id
    JOIN part_categories pc
        ON pc.category_id = p.category_id
    LEFT JOIN return_lines rl
        ON rl.order_line_id = sol.order_line_id
    LEFT JOIN returns r
        ON r.return_id = rl.return_id
)
SELECT
    COALESCE(ro.channel, 'All Channels') AS channel,
    COALESCE(ro.category_name, 'All Categories') AS category_name,
    COUNT(*) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE refund_status
    ) AS returned_orders,
    ROUND(
        COUNT(*) FILTER (WHERE refund_status) * 100.0 / COUNT(*),
        2
    ) AS return_rate,
    SUM(refund_amount) AS total_refund,
    ROUND(
        SUM(refund_amount) * 100.0 / NULLIF(SUM(line_total), 0),
        2
    ) AS refund_rate
FROM return_orders ro
GROUP BY GROUPING SETS (
    (channel, category_name),
    (channel),
    (category_name)
)
ORDER BY
    channel,
    category_name;
	
	
	

--BQ23-Most common return reasons, and which products or channels concentrate them
	
	
--1. Most common reason
select
	r.reason ,
	count(*) as total_reason
from
	"returns" r
group by
	r.reason
order by
	total_reason desc
limit 1

--2. Product
select
	r.reason,
	sol.part_id,
	count(*) as total_reason
from
	"returns" r
join return_lines rl on
	r.return_id = rl.return_id
join sales_order_lines sol on
	sol.order_line_id = rl.order_line_id
group by
	r.reason,
	sol.part_id
order by
	total_reason desc

-- 3. Sales Channel
SELECT
    r.reason,
    so.channel,
    COUNT(*) AS total_reason
FROM returns r
JOIN sales_orders so
    ON so.order_id = r.order_id
GROUP BY
    r.reason,
    so.channel
ORDER BY
    total_reason DESC;