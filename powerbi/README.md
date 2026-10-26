# Power BI dashboard — E-commerce Sales & Customer Analytics (Olist)

[`Ecommerce_Olist.pbix`](./Ecommerce_Olist.pbix) · built in Power BI Desktop · 3 pages · 39 DAX measures · data imported from
`data/cleaned/` (fact_orders 99,441 · fact_order_items 112,650 · dim_customers 93,104 · dim_state 27 rows).

| Page | Screenshot |
|---|---|
| Executive Overview | [`screenshots/powerbi_page1_executive_overview.png`](../screenshots/powerbi_page1_executive_overview.png) |
| Detailed Analysis | [`screenshots/powerbi_page2_detailed_analysis.png`](../screenshots/powerbi_page2_detailed_analysis.png) |
| Business Insights | [`screenshots/powerbi_page3_business_insights.png`](../screenshots/powerbi_page3_business_insights.png) |

## What is on each page

* **Executive Overview** — 7 KPI cards (Total revenue, Delivered orders, Average order value, Unique customers, Repeat customer rate, On-time delivery, Avg review (1-5)); Column chart — Monthly revenue (R$); Bar chart — Revenue by region (R$); Line chart — Revenue by month, Jan–Aug: 2018 vs 2017 (R$); Bar chart — Top 10 categories by revenue (R$).
* **Detailed Analysis** — Table — Category performance; Matrix (heat map) — Delivered orders by weekday and hour of purchase; Donut chart — Delivered orders by payment type; Bar chart — Top 10 states by revenue (R$).
* **Business Insights** — Column chart — Average review by delivery timing; Bar chart — Late delivery rate by region; Bar chart — Freight as % of revenue by region; Bar chart — Customer segments: share of customers vs share of revenue.

Slicers on every page (synced): Region, Year.

## Data model (star schema, single-direction many-to-one relationships)

| From (many) | To (one) |
|---|---|
| `fact_orders[purchase_date]` | `Date[Date]` |
| `fact_order_items[purchase_date]` | `Date[Date]` |
| `fact_orders[customer_state]` | `dim_state[state_code]` |
| `fact_order_items[customer_state]` | `dim_state[state_code]` |
| `fact_orders[customer_unique_id]` | `dim_customers[customer_unique_id]` |

`Date` is built in Power Query and marked as the date table. All measures live in the `_Measures` table:
[`measures.dax`](measures.dax). All queries: [`power_query.m`](power_query.m).

## Open and refresh

1. Open `Ecommerce_Olist.pbix` in Power BI Desktop (free, Windows). The data is already inside the file.
2. To reload from the CSVs: **Home → Transform data → Edit parameters → DataFolder** = the full path of this
   project's `data\cleaned\` folder (ending with `\`), then **Refresh**.

## Numbers to expect (no slicer selected)

| Measure | Value |
|---|---|
| Total Revenue | R$ 15.37M (15,373,120) |
| Delivered Orders | 96,211 |
| Average Order Value | R$ 159.79 |
| Unique Customers | 93,104 |
| Repeat Customer Rate | 3.00% |
| On-time Delivery Rate | 93.2% |
| Avg Review Score | 4.14 |

These match the notebook (`reports/kpi_summary.json`), SQL (`sql/results/`) and the Excel workbook.
