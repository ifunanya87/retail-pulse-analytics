import streamlit as st
import plotly.express as px
from visualization.bq_loader import load_all_data



st.set_page_config(layout="wide")
st.title("Geospatial Market Insights")

data = load_all_data()
df = data["county_mart"]

# DATA SEPARATION LOGIC
# Separate valid counties from the 'Unassigned' bucket
county_mask = df["county"] != "UNASSIGNED"
valid_counties = df[county_mask]
unassigned_rev = df[~county_mask]["total_revenue"].sum()

# KPI HEADER
c1, c2, c3 = st.columns(3)
with c1:
    top_county = valid_counties.groupby("county")["total_revenue"].sum().idxmax()
    st.metric("Leading County", top_county)
with c2:
    actual_count = valid_counties["county"].nunique()
    st.metric("Market Coverage", f"{actual_count}/99", help="Standardized to official Iowa counties.")
with c3:
    total_rev = df["total_revenue"].sum()
    leakage_pct = (unassigned_rev / total_rev) if total_rev > 0 else 0
    st.metric("Revenue Attribution Leakage", f"{leakage_pct:.2%}", help="Revenue from 'UNASSIGNED' locations.")

# VISUALIZATIONS
# Using valid_counties for the Bar and Map
fig = px.bar(
    valid_counties.groupby("county")["total_revenue"].sum().reset_index().sort_values("total_revenue", ascending=False),
    x="county", 
    y="total_revenue", 
    title="Revenue by Standardized County"
)
st.plotly_chart(fig, use_container_width=True)
