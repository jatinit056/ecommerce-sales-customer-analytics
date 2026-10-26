# Methodology

## Workflow

```
Raw data (8 CSVs, read-only)
  → Data understanding   (notebook §5–7: shapes, types, relationships)
  → Data cleaning        (notebook §8–11, mirrored in sql/cleaning_views.sql)
  → EDA                  (notebook §13–14)
  → SQL analysis         (sql/analysis_queries.sql, 23 queries, PostgreSQL)
  → Python analysis      (notebook §15–18: KPIs, trends, segments, correlation)
  → KPI development      (reports/kpi_summary.json — one source of truth)
  → Excel workbook       (excel/ecommerce_analysis.xlsx — live formulas + PivotTables)
  → Power BI dashboard   (powerbi/Ecommerce_Olist.pbix — star schema, DAX, 3 pages)
  → Insights & recommendations (reports/insights.md)
```

## Scope and definitions (identical in Python, SQL, Excel and Power BI)

| Term | Definition |
|---|---|
| Analysis window | Orders purchased 2017-01-01 to 2018-08-31 (20 complete months) |
| Delivered order | `order_status = 'delivered'` |
| Revenue | item price + freight, delivered orders only |
| AOV | revenue ÷ delivered orders |
| Unique customer | distinct `customer_unique_id` |
| Repeat customer rate | customers with 2+ delivered orders ÷ unique customers |
| On-time rate | delivered on or before the estimated date ÷ delivered orders with a delivery date |
| Cancellation rate | canceled + unavailable orders ÷ all orders in the window |
| Freight share | freight ÷ revenue |
| RFM segments | Repeat (2+ orders) first; one-time buyers split by spend > 75th percentile ("High-value") and recency ≤ median ("recent") |

## Why these tools

* **Python (pandas)** — cleaning, feature engineering, statistics and charts in one reproducible notebook.
* **SQL (PostgreSQL)** — the same KPIs written as queries, the way they would be produced from a company database.
  Window functions (LAG, ranking, running totals, NTILE) answer trend and ranking questions.
* **Excel** — business-user view: SUMIFS/COUNTIFS summaries, lookups, PivotTables, conditional formatting.
* **Power BI** — interactive dashboard for managers (star schema + DAX measures).

## Validation

1. **SQL vs Python reconciliation** — `scripts/reconcile_sql_python.py` compares 26 KPIs calculated independently in
   PostgreSQL and pandas: 26/26 match (see `reports/sql_python_reconciliation.md`).
2. **Excel vs Python** — the Summary sheet shows each Excel KPI next to the notebook value with a ✓/✗ check, and every
   formula was recalculated from scratch and compared with Python (`reports/excel_verification.md`).
3. **Payments vs items** — payments match item price + freight for 99.61% of orders.
4. **No hand-typed numbers** — every number in the README and reports comes from `reports/kpi_summary.json` or the SQL
   result files.

## Limitations

* No cost data → no profit or margin analysis.
* Product names are anonymised → products are identified by ID and category only.
* One marketplace in one country (Brazil, 2017–2018); results describe Olist, not e-commerce in general.
* Correlation ≠ causation: the link between late delivery and low reviews is strong and consistent, but other factors
  (product quality, seller behaviour) also matter.
