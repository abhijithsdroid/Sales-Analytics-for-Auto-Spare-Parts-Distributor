SELECT * FROM returns r;

SELECT DISTINCT status FROM returns;

SELECT * FROM return_lines rl;

SELECT * FROM sales_orders so;

SELECT * FROM sales_order_lines sol;

SELECT * FROM part_categories pc;


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