# SQL business questions

Each query in `analysis_queries.sql` answers one business question. Queries run on PostgreSQL 16 against the schema in `schema.sql` and the cleaning views in `cleaning_views.sql`. Full outputs: `results/Q01.csv` … `results/Q23.csv`; preview of all outputs: `results/summary.md`.

| # | Business question | SQL concepts | Key result (from the actual run) |
|---|---|---|---|
| Q01 | How are all orders split by status? | GROUP BY, COUNT, scalar subquery | 97.02% of orders delivered; 625 canceled, 609 unavailable |
| Q02 | What are the headline KPIs (orders, revenue, AOV, customers)? | Aggregates, COUNT DISTINCT, view | 96,211 orders · R$15.37M · AOV R$159.79 · 93,104 customers |
| Q03 | Which payment methods do customers use and how much do they pay? (all payment records) | GROUP BY, AVG, WHERE | Credit card R$12.54M paid, avg 3.51 installments |
| Q04 | Which 10 states generate the most revenue? | INNER JOIN ×2, WHERE, GROUP BY, LIMIT | SP R$5.76M, RJ R$2.05M, MG R$1.81M |
| Q05 | What is the monthly revenue and order trend? | DATE_TRUNC, TO_CHAR | 20 months; peak 2017-11 (R$1.15M) |
| Q06 | How are orders distributed across order-value bands? | CASE WHEN, window SUM() OVER () | R$500+ orders: 4.2% of orders, 24.4% of revenue |
| Q07 | Which categories earn the most? | INNER + LEFT JOIN, COALESCE | Top: health_beauty R$1.41M |
| Q08 | Which orders have no items or no payment? (data quality) | LEFT JOIN … IS NULL, FILTER, HAVING | 775 orders without items (mostly unavailable/canceled); 1 without payment |
| Q09 | Which states have the slowest / most often late deliveries? | CASE inside AVG, HAVING | Worst: MA 17.5% late; best: PR 4.1% |
| Q10 | How does delivery timing affect the review score? | CASE WHEN bands, AVG | 8+ days late: 1.69★, 79.5% 1–2★ |
| Q11 | On which weekdays do customers order most? | EXTRACT(ISODOW), TO_CHAR | Busiest: Monday; quietest: Saturday |
| Q12 | How many customers came back for a second order? | CTE, FILTER | 2,789 repeat customers = 3.00% |
| Q13 | Which categories earn more than the average category? | Subquery in HAVING | 18 categories above the category average |
| Q14 | What is the month-over-month revenue growth? | CTE + LAG | Nov 2017 (Black Friday month): +53.5% vs Oct; Dec 2017: -26.9% |
| Q15 | What is the year-to-date running revenue? | SUM() OVER (PARTITION BY … ORDER BY …) | 2017 full-year revenue R$6.92M |
| Q16 | What are the top 3 categories in each region? | DENSE_RANK + PARTITION BY | South-East #1: Bed bath table; other regions: Health beauty / Sports leisure |
| Q17 | What are the best-selling products in each top category? | ROW_NUMBER + CTEs + JOIN | Best product overall: bb50f2e2… (Health beauty) |
| Q18 | How concentrated is revenue across categories (Pareto)? | RANK, cumulative SUM window | 18 categories reach 80% of revenue |
| Q19 | How much revenue do the top 10% of sellers generate? | NTILE(10) | Top decile of sellers = 66.2% of revenue |
| Q20 | How many customers / how much revenue in each RFM segment? | PERCENTILE_CONT, CROSS JOIN, CASE | High-value recent + lapsed = 54.7% of revenue |
| Q21 | How long do repeat customers take to place a 2nd order? | LEAD, ROW_NUMBER | 29.7% of 2nd orders on the same day |
| Q22 | How did Jan–Aug 2018 compare with Jan–Aug 2017? | Conditional aggregation (FILTER) | Revenue +143.36%, orders +139.94% |
| Q23 | How big was Black Friday compared with a normal week? | Moving average window frame, RANK | Black Friday = 4.9× previous-7-day average, rank 1 |

## How to run

```bash
createdb olist_db
psql -d olist_db -f sql/schema.sql
psql -d olist_db -f sql/load_data.sql        # run from the project root
psql -d olist_db -f sql/cleaning_views.sql
psql -d olist_db -f sql/analysis_queries.sql
# or save every result as CSV:
python scripts/run_sql_queries.py --db olist_db
```

## Why views?

`cleaning_views.sql` turns the raw tables into analysis-ready views (`v_orders`, `v_delivered_orders`, `v_delivered_items`, `v_products`) that apply the same cleaning rules as the Python notebook (one review per order, English category names, delivery metrics, analysis window). Queries that only need these rules use the views; queries that demonstrate joins (Q04, Q07, Q08) use the raw tables directly.
