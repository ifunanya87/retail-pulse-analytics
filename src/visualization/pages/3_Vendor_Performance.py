import streamlit as st
import pandas as pd
import plotly.express as px
from visualization.bq_loader import load_all_data
from visualization.charts import pareto_chart, hhi_index



st.set_page_config(layout="wide")
st.title("Vendor Performance")

data = load_all_data()
vendor = data["vendor_mart"] 

# KPI Header
pareto_data = vendor.groupby("vendor_name_standardized")["total_revenue"].sum().reset_index()
hhi = hhi_index(pareto_data, "total_revenue")
st.metric("Market Concentration (HHI)", f"{hhi:.3f}", help="HHI > 0.25 indicates high concentration")

top = pareto_data.sort_values("total_revenue", ascending=False).head(10)
fig = px.bar(top, x="vendor_name_standardized", y="total_revenue", title="Top Vendors")
st.plotly_chart(fig, use_container_width=True)

fig2 = pareto_chart(pareto_data, "vendor_name_standardized", "total_revenue")
st.plotly_chart(fig2, use_container_width=True)
