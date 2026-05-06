import streamlit as st
import plotly.express as px
from visualization.bq_loader import load_all_data



st.set_page_config(layout="wide")
st.title("Market Momentum")

data = load_all_data()
category = data["category_mart"]

growth = category.groupby("category_name_standardized")["mom_growth_pct"].mean().reset_index()

fig = px.bar(
    growth.sort_values("mom_growth_pct", ascending=False),
    x="category_name_standardized",
    y="mom_growth_pct",
    title="Average Category Growth Momentum"
)
st.plotly_chart(fig, use_container_width=True)

pivot = category.pivot_table(
    index="category_name_standardized",
    columns="sales_month",
    values="mom_growth_pct"
)
fig2 = px.imshow(pivot, title="Growth Acceleration Heatmap", color_continuous_scale="RdBu_r")
st.plotly_chart(fig2, use_container_width=True)
