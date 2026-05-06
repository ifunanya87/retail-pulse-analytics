import streamlit as st
import plotly.express as px
from visualization.bq_loader import load_all_data



st.set_page_config(layout="wide")
st.title("Executive Overview")

data = load_all_data()
fct = data["sales_fct"]
category = data["category_mart"]

# KPI HEADER
col1, col2, col3 = st.columns(3)
with col1:
    total_revenue = fct["revenue"].sum()
    st.metric("Total Revenue", f"${total_revenue:,.0f}")
with col2:
    total_vol = fct["volume_liters_sold"].sum()
    st.metric("Total Volume (Liters)", f"{total_vol:,.0f}")
with col3:
    avg_price = fct["avg_unit_price"].mean()
    st.metric("Avg Unit Price", f"${avg_price:,.2f}")

st.divider()

# REVENUE TREND
# Aggregating to a rolling average
trend = fct.groupby("transaction_date")["revenue"].sum().reset_index()
trend["moving_avg"] = trend["revenue"].rolling(window=7).mean()

fig = px.line(trend, x="transaction_date", y=["revenue", "moving_avg"], 
             title="Revenue Trend: Daily vs. 7-Day Moving Average",
             labels={"value": "Revenue", "variable": "Metric"})

# Styling for clarity
fig.update_traces(line=dict(width=1), selector=dict(name="revenue"))
fig.update_traces(line=dict(width=3, color="gold"), selector=dict(name="moving_avg"))

st.plotly_chart(fig, use_container_width=True)

# CATEGORY SHARE
cat = category.groupby("category_name_standardized")["total_revenue"].sum().reset_index()
fig2 = px.bar(cat.sort_values("total_revenue", ascending=False), 
             x="category_name_standardized", y="total_revenue", title="Revenue by Category")
st.plotly_chart(fig2, use_container_width=True)
