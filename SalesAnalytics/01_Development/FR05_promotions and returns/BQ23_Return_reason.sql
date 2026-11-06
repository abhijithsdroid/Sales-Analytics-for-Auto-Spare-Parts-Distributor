select * from "returns" r

-- 1. Most common reason
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