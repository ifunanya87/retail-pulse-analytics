import streamlit as st
import plotly.express as px
from visualization.bq_loader import load_all_data
from visualization.charts import cluster_stores



st.set_page_config(layout="wide")
st.title("Store Performance")

data = load_all_data()
store = data["store_mart"]

# KPI HEADER
col1, col2 = st.columns(2)
active_stores = store["store_id"].nunique()
avg_store_rev = store["total_revenue"].mean()

col1.metric("Total Active Stores", active_stores)
col2.metric("Avg Revenue per Store", f"${avg_store_rev:,.0f}")

st.divider()

# SORTED BAR CHART
top_stores = store.sort_values("total_revenue", ascending=False).head(10).copy()
top_stores["store_id"] = top_stores["store_id"].astype(str) 

fig = px.bar(
    top_stores, 
    x="store_id", 
    y="total_revenue", 
    hover_data=["store_name"], 
    title="Top 10 Stores by Revenue (Ranked)"
)

fig.update_xaxes(
    type='category',
    categoryorder='array', 
    categoryarray=top_stores['store_id'].tolist()
)

st.plotly_chart(fig, use_container_width=True)

# SEGMENTATION
clustered = cluster_stores(store.copy())
fig_cluster = px.scatter(
    clustered,
    x="total_volume_liters",
    y="total_revenue",
    color="cluster",
    hover_data=["store_name"],
    title="Store Segmentation (K-Means)"
)
st.plotly_chart(fig_cluster, use_container_width=True)
