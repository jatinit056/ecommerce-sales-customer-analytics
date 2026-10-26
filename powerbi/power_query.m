// =====================================================================
// Power Query (M) of powerbi/Ecommerce_Olist.pbix — one block per query.
// DataFolder is a text parameter: the folder that holds the cleaned CSVs (must end with \).
// =====================================================================

// ---------- Parameter: DataFolder ----------
"<path to this project>\data\cleaned\" meta [IsParameterQuery = true, Type = "Text", IsParameterQueryRequired = true]

// ---------- Query: fact_orders ----------
let
    Source = Csv.Document(File.Contents(DataFolder & "fact_orders.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    Blanks = Table.ReplaceValue(Promoted, "", null, Replacer.ReplaceValue, Table.ColumnNames(Promoted)),
    Typed = Table.TransformColumnTypes(Blanks, {{"order_id", type text}, {"customer_unique_id", type text}, {"customer_state", type text}, {"customer_region", type text}, {"customer_city", type text}, {"order_status", type text}, {"is_delivered", type logical}, {"is_canceled", type logical}, {"in_analysis_window", type logical}, {"order_purchase_timestamp", type datetime}, {"purchase_date", type date}, {"year_month", type text}, {"purchase_year", Int64.Type}, {"purchase_weekday", type text}, {"purchase_hour", Int64.Type}, {"items_count", Int64.Type}, {"product_revenue", type number}, {"freight_value", type number}, {"order_revenue", type number}, {"main_category", type text}, {"primary_payment_type", type text}, {"max_installments", Int64.Type}, {"review_score", Int64.Type}, {"delivery_days", type number}, {"delay_days", Int64.Type}, {"is_late", type logical}, {"dq_issue", type text}}, "en-US"),
    Step1 = Table.AddColumn(Typed, "in_scope", each [is_delivered] = true and [in_analysis_window] = true, type logical),
    Step2 = Table.AddColumn(Step1, "delivery_status", each if [is_late] = null then "Not delivered" else if [is_late] then "Late" else "On time", type text),
    Step3 = Table.AddColumn(Step2, "delivery_timing", each if [delay_days] = null then null else if [delay_days] <= -8 then "1. 8+ days early" else if [delay_days] <= 0 then "2. 0-7 days early" else if [delay_days] <= 7 then "3. 1-7 days late" else "4. 8+ days late", type text),
    Step4 = Table.AddColumn(Step3, "weekday_number", each Date.DayOfWeek([purchase_date], Day.Monday) + 1, Int64.Type)
in
    Step4

// ---------- Query: fact_order_items ----------
let
    Source = Csv.Document(File.Contents(DataFolder & "fact_order_items.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    Blanks = Table.ReplaceValue(Promoted, "", null, Replacer.ReplaceValue, Table.ColumnNames(Promoted)),
    Typed = Table.TransformColumnTypes(Blanks, {{"order_id", type text}, {"order_item_id", Int64.Type}, {"product_id", type text}, {"seller_id", type text}, {"category", type text}, {"seller_state", type text}, {"customer_state", type text}, {"purchase_date", type date}, {"year_month", type text}, {"order_status", type text}, {"is_delivered", type logical}, {"in_analysis_window", type logical}, {"price", type number}, {"freight_value", type number}, {"item_revenue", type number}}, "en-US"),
    Step1 = Table.AddColumn(Typed, "in_scope", each [is_delivered] = true and [in_analysis_window] = true, type logical)
in
    Step1

// ---------- Query: dim_customers ----------
let
    Source = Csv.Document(File.Contents(DataFolder & "dim_customers.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    Blanks = Table.ReplaceValue(Promoted, "", null, Replacer.ReplaceValue, Table.ColumnNames(Promoted)),
    Typed = Table.TransformColumnTypes(Blanks, {{"customer_unique_id", type text}, {"customer_state", type text}, {"customer_city", type text}, {"first_purchase_date", type date}, {"last_purchase_date", type date}, {"orders_count", Int64.Type}, {"total_revenue", type number}, {"avg_order_value", type number}, {"recency_days", Int64.Type}, {"is_repeat_customer", type logical}, {"r_score", Int64.Type}, {"m_score", Int64.Type}, {"segment", type text}}, "en-US")
in
    Typed

// ---------- Query: dim_state ----------
let
    Source = Csv.Document(File.Contents(DataFolder & "dim_state.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    Blanks = Table.ReplaceValue(Promoted, "", null, Replacer.ReplaceValue, Table.ColumnNames(Promoted)),
    Typed = Table.TransformColumnTypes(Blanks, {{"state_code", type text}, {"state_name", type text}, {"region", type text}, {"map_location", type text}}, "en-US")
in
    Typed

// ---------- Query: Date ----------
let
    StartDate = #date(2016, 9, 1),
    EndDate = #date(2018, 10, 31),
    Dates = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1, 0, 0, 0)),
    AsTable = Table.FromList(Dates, Splitter.SplitByNothing(), {"Date"}),
    Typed = Table.TransformColumnTypes(AsTable, {{"Date", type date}}),
    AddYear = Table.AddColumn(Typed, "Year", each Date.Year([Date]), Int64.Type),
    AddMonthNo = Table.AddColumn(AddYear, "Month Number", each Date.Month([Date]), Int64.Type),
    AddMonthStart = Table.AddColumn(AddMonthNo, "Month Start", each Date.StartOfMonth([Date]), type date),
    AddMonth = Table.AddColumn(AddMonthStart, "Month", each Date.ToText([Date], "MMM yyyy", "en-US"), type text),
    AddMonthName = Table.AddColumn(AddMonth, "Month Name", each Date.ToText([Date], "MMM", "en-US"), type text),
    AddWeekdayNo = Table.AddColumn(AddMonthName, "Weekday Number", each Date.DayOfWeek([Date], Day.Monday) + 1, Int64.Type),
    AddWeekday = Table.AddColumn(AddWeekdayNo, "Weekday", each Date.ToText([Date], "ddd", "en-US"), type text)
in
    AddWeekday
