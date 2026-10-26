# Excel workbook verification

Workbook: [`excel/ecommerce_analysis.xlsx`](../excel/ecommerce_analysis.xlsx) · 976,562 formulas · checked 22 Oct 2026

**Result: 46 of 46 checks passed.**

## How the workbook was checked

1. **Structure** — the file was opened with `openpyxl` to confirm the Excel Tables, named ranges, PivotTables,
   conditional-formatting rules and the Excel functions used.
2. **Full recalculation** — every formula was recalculated from scratch in LibreOffice Calc (headless) and the results
   were compared with the values stored in the file.
3. **Independent numbers** — the recalculated results were compared with values computed separately in pandas from the
   cleaned CSV files, the notebook KPIs (`reports/kpi_summary.json`) and the SQL results (`sql/results/`).

The recalculation was done in **LibreOffice, not Microsoft Excel**. The file is a standard `.xlsx` built for Excel
2019 / 2021 / 365; the PivotTables are set to refresh when the file is opened.

## Checks

| # | Check | Result |
|---|---|---|
| 1 | defined names present | PASS |
| 2 | Excel tables present | PASS |
| 3 | pivot tables parsed by openpyxl | PASS |
| 4 | data validation on category lookup | PASS |
| 5 | conditional formatting rules present | PASS |
| 6 | analysis sheets contain formulas | PASS |
| 7 | uses SUMIFS | PASS |
| 8 | uses COUNTIFS | PASS |
| 9 | uses AVERAGEIFS | PASS |
| 10 | uses VLOOKUP | PASS |
| 11 | uses INDEX | PASS |
| 12 | uses MATCH | PASS |
| 13 | uses XLOOKUP | PASS |
| 14 | uses IFS | PASS |
| 15 | uses IF | PASS |
| 16 | uses PERCENTILE.INC | PASS |
| 17 | uses RANK.EQ | PASS |
| 18 | uses LARGE | PASS |
| 19 | uses EDATE | PASS |
| 20 | uses TEXT | PASS |
| 21 | uses DATE | PASS |
| 22 | analysis formulas: no errors after LibreOffice recalculation | PASS |
| 23 | analysis formulas: recalculated = cached values | PASS |
| 24 | Orders: row formulas recalculated = pandas values | PASS |
| 25 | Customers: row formulas recalculated = pandas values | PASS |
| 26 | Summary revenue = pandas | PASS |
| 27 | Summary delivered orders = pandas | PASS |
| 28 | Summary AOV = KPI | PASS |
| 29 | Summary unique customers = pandas | PASS |
| 30 | Summary repeat rate = KPI | PASS |
| 31 | Summary on-time rate = KPI | PASS |
| 32 | Summary avg review = KPI | PASS |
| 33 | Summary cancellation rate = KPI | PASS |
| 34 | Summary ✓ checks all pass | PASS |
| 35 | Monthly_Trend orders & revenue = pandas (20 months) | PASS |
| 36 | Monthly_Trend YoY growth = KPI | PASS |
| 37 | Category_Analysis items & revenue = pandas (74 categories) | PASS |
| 38 | Category_Analysis core categories = 18 (Python Pareto) | PASS |
| 39 | Category lookup (XLOOKUP fallback) returns revenue | PASS |
| 40 | State_Region revenue = pandas (27 states) | PASS |
| 41 | State_Region region late rates = KPI | PASS |
| 42 | Segment thresholds = Python quartiles | PASS |
| 43 | Segment sizes (IFS formulas) = Python segments | PASS |
| 44 | Delivery timing bands = pandas | PASS |
| 45 | Payment type counts = pandas | PASS |
| 46 | Pivot 1 category totals = pandas | PASS |
