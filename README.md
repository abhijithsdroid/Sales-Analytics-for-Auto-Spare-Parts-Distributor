# Sales Analytics: Auto Spare-Parts Distributor (SQL)

End-to-end sales analytics for a multi-tier automobile spare-parts distributor selling through **Dealer**, **Retail** and **Online** channels. The whole project is written in **SQL** on a PostgreSQL database (`auto_parts_analytics`), covering **600K orders** and **1.8M order lines** from **2022 to 2025**.

## Business Problem

The business wanted to know where revenue is made and lost, which customers and dealers are valuable, what drives the order funnel, which products to push or retire, and what discounting actually buys. The goal was a small set of trustworthy SQL views that Sales Operations leadership could use directly.

## Dataset

| Item | Detail |
|---|---|
| Database | PostgreSQL 14+, `auto_parts_analytics` |
| Period | 2022–2025 (4 fiscal years, daily grain) |
| Sales orders | 600,000 |
| Order lines | ~1.81M |
| Channels | Dealer, Retail, Online |
| Tables in scope | 18 (of 32 in the database) |

Main tables: `sales_orders`, `sales_order_lines`, `shipments`, `returns`, `return_lines`, `retail_customers`, `dealers`, `employees`, `parts`, `part_categories`, `manufacturers`, `price_history`, `promotions`, `warehouses`, `part_vehicle_compatibility`.

## Project Modules

| ID | Module | Key techniques |
|---|---|---|
| FR-1 | Revenue & sales trend analysis | `LAG`, date bucketing, `ROLLUP` |
| FR-2 | Sales channel & order funnel performance | `CASE` / `FILTER`, funnel rates, date differences |
| FR-3 | Customer & dealer analytics | `NTILE` RFM, CLV, cohort retention, self-joins |
| FR-4 | Product & category performance | Recursive CTE, cumulative % (Pareto), margin analysis |
| FR-5 | Promotions & returns impact | Promo lift net of discount, ratio metrics |
| FR-6 | Representative, region & warehouse performance | `RANK` / `DENSE_RANK`, conditional aggregation |
| FR-7 | Executive KPI view layer | 7 reusable `CREATE VIEW` objects |

## Key Findings

**Revenue and channels**
- The Dealer channel generates roughly 15x the revenue of Online or Retail.
- South Asia is the highest revenue-generating region.
- About 4% of revenue is lost to cancellations and about 8% to discounts.

**Fulfilment and returns**
- Average shipping time is 2 days and average delivery time is 8 days.
- Retail in Sub-Saharan Africa has the most delayed orders.
- Online in Eastern Europe has the most returned orders.
- Engine Mounts (Online) is the most returned category, and Duplicate Orders is the most common return reason.

**Customers and dealers**
- Bronze-tier dealers perform strongly in generating revenue.

**Products**
- 9,531 parts generate 80% of total revenue.
- Premium Car Batteries generate the highest revenue.
- Spark Plugs in the Electrical category have a high profit margin.
- Non-OEM products outnumber OEM products by almost 3 to 1.
- Parts for the Tata Terra generate the highest vehicle-level revenue.

**People and warehouses**
- Southeast Asia is the best-performing region by average order value.
- North Africa Distribution Center 5 is the best-utilised warehouse.
- Latin America Distribution Center 9 has the most returned orders.

## Executive Views (FR-7)

1. Monthly Sales Performance Growth
2. Customer Segments
3. Dealers Performance by Credit Utilization
4. Product & Category Performance
5. Sales Order Funnel Performance
6. Sales Representatives Performance
7. Regional & Warehouse Performance

Each view can be queried with a plain `SELECT *` and returns a documented grain.

## Assumptions

- Revenue is recognised on `order_status = 'Delivered'`; cancelled orders are excluded and quantified separately as leakage; Pending, Confirmed and Shipped orders are treated as pipeline.
- Single currency, no time-zone handling, no PII masking.


