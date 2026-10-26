"""Reconcile the SQL results (sql/results/*.csv) with the Python notebook outputs.

The same KPI is calculated twice - once in PostgreSQL, once in pandas - and must agree.
Run after the notebook and scripts/run_sql_queries.py:
    python scripts/reconcile_sql_python.py
Writes reports/sql_python_reconciliation.md and exits with code 1 if any check fails.
"""
import json
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "sql" / "results"
kpi = json.loads((ROOT / "reports" / "kpi_summary.json").read_text())
orders = pd.read_csv(ROOT / "data" / "cleaned" / "fact_orders.csv")
customers = pd.read_csv(ROOT / "data" / "cleaned" / "dim_customers.csv")
delivered = orders[orders["is_delivered"] & orders["in_analysis_window"]]

checks = []


def check(name, sql_value, python_value, tolerance=0.0):
    ok = abs(float(sql_value) - float(python_value)) <= tolerance
    checks.append((name, sql_value, python_value, "PASS" if ok else "FAIL"))


q = {f.stem: pd.read_csv(f) for f in sorted(RES.glob("Q*.csv"))}

q02 = q["Q02"].iloc[0]
check("Delivered orders (Q02)", q02["delivered_orders"], kpi["delivered_orders"])
check("Total revenue R$ (Q02)", q02["total_revenue"], kpi["total_revenue"], 0.01)
check("Average order value R$ (Q02)", q02["avg_order_value"], round(kpi["avg_order_value"], 2), 0.005)
check("Unique customers (Q02)", q02["unique_customers"], kpi["unique_customers"])
check("Freight share % (Q02)", q02["freight_share_pct"], round(kpi["freight_share_of_revenue"] * 100, 2), 0.01)

q12 = q["Q12"].iloc[0]
check("Repeat customers (Q12)", q12["repeat_customers"], kpi["repeat_customers"])
check("Repeat revenue share % (Q12)", q12["repeat_revenue_share_pct"], round(kpi["repeat_revenue_share_pct"], 2), 0.01)

segments = customers["segment"].value_counts()
for _, row in q["Q20"].iterrows():
    check(f"Segment size: {row['segment']} (Q20)", row["customers"], segments.get(row["segment"], 0))

monthly = delivered.groupby("year_month")["order_revenue"].sum().round(2)
q05 = q["Q05"].set_index("month")["revenue"]
check("Monthly revenue: months compared (Q05)", len(q05), len(monthly))
check("Monthly revenue: max abs difference R$ (Q05)", (q05 - monthly).abs().max(), 0, 0.05)

d = delivered.dropna(subset=["delay_days"])
bands = pd.cut(d["delay_days"], bins=[-1000, -8, 0, 7, 1000], labels=["1", "2", "3", "4"]).value_counts()
for _, row in q["Q10"].iterrows():
    check(f"Delivery-timing band {row['delivery_status']} orders (Q10)", row["orders"], bands[row["delivery_status"][0]])

q18 = q["Q18"]
first_rank_80 = int(q18.loc[q18["cumulative_share_pct"] >= 80, "category_rank"].iloc[0])
check("Categories needed for 80% of revenue (Q18)", first_rank_80, kpi["categories_for_80pct_revenue"])

q19 = q["Q19"]
check("Top-10% sellers revenue share % (Q19)", q19.loc[q19["revenue_decile"] == 1, "revenue_share_pct"].iloc[0],
      round(kpi["top10pct_sellers_revenue_share_pct"], 2), 0.01)

q22 = q["Q22"].iloc[0]
check("YoY revenue growth % (Q22)", q22["revenue_growth_pct"], round(kpi["yoy_revenue_growth_pct"], 2), 0.01)
check("YoY order growth % (Q22)", q22["order_growth_pct"], round(kpi["yoy_orders_growth_pct"], 2), 0.01)

q09 = q["Q09"].iloc[0]
check(f"Worst late-delivery state {q09['customer_state']} late rate % (Q09)", q09["late_rate_pct"],
      round(kpi["worst_late_state_rate_pct"], 2), 0.01)

q04 = q["Q04"].set_index("customer_state")
state_rev = delivered.groupby("customer_state")["order_revenue"].sum()
check("SP revenue R$ (Q04)", q04.loc["SP", "revenue"], state_rev["SP"], 0.05)

q23 = q["Q23"]
bf = q23[q23["purchase_date"] == kpi["best_day"]].iloc[0]
check("Best day revenue R$ (Q23)", bf["revenue"], kpi["best_day_revenue"], 0.01)
check("Best day is revenue rank 1 (Q23)", bf["revenue_rank"], 1)

report = ["# SQL vs Python reconciliation", "",
          "Each KPI below was calculated independently in PostgreSQL (`sql/analysis_queries.sql`) and in pandas "
          "(`notebooks/`). A check passes when both agree (money within R$0.05, percentages within 0.01 points).", "",
          "| Check | SQL | Python | Result |", "|---|---|---|---|"]
for name, s, p, r in checks:
    report.append(f"| {name} | {s} | {round(float(p), 4)} | {r} |")
passed = sum(c[3] == "PASS" for c in checks)
report += ["", f"**{passed} of {len(checks)} checks passed.**"]
(ROOT / "reports" / "sql_python_reconciliation.md").write_text("\n".join(report) + "\n", encoding="utf-8")
print("\n".join(report))
raise SystemExit(0 if passed == len(checks) else 1)
