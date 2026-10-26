# Business insights — E-commerce Sales & Customer Analytics (Olist)

Scope: 96,211 delivered orders, 93,104 customers, Jan 2017 – Aug 2018. Every number comes from `reports/kpi_summary.json` (notebook) or `sql/results/` (PostgreSQL).

## 1. Revenue more than doubled year over year — driven by order volume, not basket size

**Insight:** Jan–Aug 2018 revenue was R$8.45M vs R$3.47M in Jan–Aug 2017 (+143.4%). Orders grew +139.9%, but AOV changed only +1.4%.

**Business impact:** Growth depends on acquiring more orders. If acquisition slows, revenue slows — there is no basket-size growth to fall back on.

**Recommendation:** Add basket-building levers (bundles, free-shipping thresholds, cross-sell of top categories) so growth is not only volume-driven.

## 2. Black Friday is the single biggest sales moment

**Insight:** 24 November 2017 (Black Friday) produced R$175.2K from 1,147 delivered orders — 7.5× a median day and 4.9× the average of the previous 7 days. November 2017 was the top month (R$1.15M).

**Business impact:** One week of the year concentrates demand; stock-outs or delivery delays there hurt both revenue and reviews.

**Recommendation:** Plan Black Friday 6–8 weeks ahead: seller stock, carrier capacity, customer-service staffing and realistic delivery promises.

## 3. Almost every customer buys only once

**Insight:** Only 3.0% of 93,104 customers placed a second delivered order, and for 29.7% of them the second order came on the same day as the first. Repeat customers spend R$308.55 vs R$160.69.

**Business impact:** Revenue relies on constant new-customer acquisition, which is expensive. Even a small lift in repeat rate is valuable.

**Recommendation:** Launch post-delivery retention: 'buy again' emails at 30/60/90 days, a second-order coupon, and track repeat rate monthly.

## 4. High-value one-time buyers are the most valuable group — and half of them have gone quiet

**Insight:** The two High-value segments are 23.1% of customers but 54.7% of revenue. 10,631 of them (27.1% of revenue) last bought more than 221 days before the data ends.

**Business impact:** These customers already trust the marketplace with large purchases; losing them is costly.

**Recommendation:** Run a win-back campaign for 'High-value lapsed' customers with personalised offers in the categories they bought.

## 5. Revenue is concentrated in a few categories

**Insight:** 18 of 74 categories generate 80% of revenue; the top 3 (Health beauty, Watches gifts, Bed bath table) generate 25.3%. 55.0% of the 32,081 products sold only once.

**Business impact:** The business is exposed to a handful of categories; problems there (stock, quality, sellers) move total revenue.

**Recommendation:** Protect the core categories (availability, seller SLAs, pricing) and use them as entry points for cross-selling the long tail.

## 6. The South-East dominates revenue

**Insight:** The South-East region generates 64.6% of revenue and São Paulo alone 37.4%. The North generates only 2.6%. The top category in the South-East is Bed bath table; in every other region it is Health beauty or Sports leisure.

**Business impact:** Regional demand is very uneven; national averages hide very different markets.

**Recommendation:** Plan marketing and assortment by region; treat SP as the core market and the North/North-East as growth markets.

## 7. Customers outside the South-East pay more for shipping and wait twice as long

**Insight:** Freight is 13.2% of order value in the South-East but 18.5% in the North (highest state: RR 21.8%). Average delivery takes 10.7 days in the South-East vs 22.6 days in the North.

**Business impact:** High freight and slow delivery are barriers to growth outside the core market — and 64.6% of sellers' revenue comes from SP-based sellers.

**Recommendation:** Test free-shipping thresholds or freight subsidies in the North/North-East, and recruit sellers outside SP to shorten delivery distances.

## 8. Late delivery is the strongest driver of bad reviews

**Insight:** On-time orders average 4.28★ vs 2.26★ for late orders. 49.9% of orders 1–7 days late and 79.5% of orders 8+ days late get a 1–2★ review, vs 9.5% of on-time orders. Delivery time has the strongest correlation with review score of all order features (r = -0.34).

**Business impact:** Bad reviews reduce conversion for the seller and the marketplace; logistics, not product, drives most dissatisfaction here.

**Recommendation:** Make on-time delivery a seller and carrier KPI; message customers proactively when an order will be late.

## 9. Late deliveries are concentrated in the North-East

**Insight:** Overall 93.2% of orders arrive on time (6,531 late orders). The late rate is 12.8% in the North-East vs 6.1% in the South-East; MA has the highest late rate (17.5%, states with 500+ orders) vs 4.5% in SP.

**Business impact:** The estimated delivery dates in these states are not reliable, so customers there are disappointed more often.

**Recommendation:** Start the delivery-improvement programme in the North-East: review carriers, add buffer to promised dates, monitor weekly.

## 10. Most customers pay by credit card and spread the cost

**Insight:** 75.5% of orders are paid mainly by credit card and 67.9% of card orders use installments. Orders paid in 7–10 installments average R$333.31 vs R$100.65 for single payments. Boleto (bank slip) is 19.9% of orders.

**Business impact:** Installments make larger purchases affordable; they are linked to much bigger baskets (correlation, not proven cause).

**Recommendation:** Promote interest-free installments on higher-priced categories, and keep boleto for customers without cards.

## 11. A small group of sellers drives most revenue

**Insight:** The top 10% of 2,945 active sellers generate 66.2% of revenue (SQL Q19, NTILE).

**Business impact:** Losing a few large sellers would hurt revenue; their service levels shape the customer experience.

**Recommendation:** Give top sellers account management and SLAs; build a development programme to grow mid-tier sellers.

## 12. Orders cluster on weekdays and late mornings to evenings

**Insight:** Monday is the busiest day and Saturday the quietest; 75.7% of orders are placed between 10:00 and 21:59. Order value bands: 4.2% of orders are R$500+, but they bring 24.4% of revenue.

**Business impact:** Timing matters for campaigns and customer-service staffing; a small share of big orders carries a large share of revenue.

**Recommendation:** Schedule campaigns and pushes for weekday mornings/early afternoons; staff support accordingly; give big-basket orders priority handling.

## What the data cannot tell us

* **Profit / margin** — no product cost, seller commission or marketing cost in the dataset.
* **Why customers did not return** — no browsing, marketing or competitor data.
* **Product names** — anonymised, so products are analysed by ID and category only.
