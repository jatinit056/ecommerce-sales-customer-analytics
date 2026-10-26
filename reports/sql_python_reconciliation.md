# SQL vs Python reconciliation

Each KPI below was calculated independently in PostgreSQL (`sql/analysis_queries.sql`) and in pandas (`notebooks/`). A check passes when both agree (money within R$0.05, percentages within 0.01 points).

| Check | SQL | Python | Result |
|---|---|---|---|
| Delivered orders (Q02) | 96211.0 | 96211.0 | PASS |
| Total revenue R$ (Q02) | 15373120.01 | 15373120.01 | PASS |
| Average order value R$ (Q02) | 159.79 | 159.79 | PASS |
| Unique customers (Q02) | 93104.0 | 93104.0 | PASS |
| Freight share % (Q02) | 14.26 | 14.26 | PASS |
| Repeat customers (Q12) | 2789.0 | 2789.0 | PASS |
| Repeat revenue share % (Q12) | 5.6 | 5.6 | PASS |
| Segment size: High-value recent (Q20) | 10882 | 10882.0 | PASS |
| Segment size: High-value lapsed (Q20) | 10631 | 10631.0 | PASS |
| Segment size: Regular recent (Q20) | 34259 | 34259.0 | PASS |
| Segment size: Regular lapsed (Q20) | 34543 | 34543.0 | PASS |
| Segment size: Repeat customers (Q20) | 2789 | 2789.0 | PASS |
| Monthly revenue: months compared (Q05) | 20 | 20.0 | PASS |
| Monthly revenue: max abs difference R$ (Q05) | 0.0 | 0.0 | PASS |
| Delivery-timing band 1. 8+ days early orders (Q10) | 71046 | 71046.0 | PASS |
| Delivery-timing band 2. 0-7 days early orders (Q10) | 18626 | 18626.0 | PASS |
| Delivery-timing band 3. 1-7 days late orders (Q10) | 3671 | 3671.0 | PASS |
| Delivery-timing band 4. 8+ days late orders (Q10) | 2860 | 2860.0 | PASS |
| Categories needed for 80% of revenue (Q18) | 18 | 18.0 | PASS |
| Top-10% sellers revenue share % (Q19) | 66.21 | 66.21 | PASS |
| YoY revenue growth % (Q22) | 143.36 | 143.36 | PASS |
| YoY order growth % (Q22) | 139.94 | 139.94 | PASS |
| Worst late-delivery state MA late rate % (Q09) | 17.53 | 17.53 | PASS |
| SP revenue R$ (Q04) | 5755999.76 | 5755999.76 | PASS |
| Best day revenue R$ (Q23) | 175178.46 | 175178.46 | PASS |
| Best day is revenue rank 1 (Q23) | 1 | 1.0 | PASS |

**26 of 26 checks passed.**
