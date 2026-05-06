import streamlit as st
import plotly.express as px
from visualization.bq_loader import load_all_data



st.set_page_config(layout="wide")
st.title("Efficiency Analysis")

data = load_all_data()
store = data["store_mart"]

store["efficiency"] = store["total_revenue"] / store["total_volume_liters"]

st.metric("Avg Portfolio Efficiency", f"${store['efficiency'].mean():.2f}/L")

fig = px.scatter(
    store,
    x="total_volume_liters",
    y="efficiency",
    title="Store Efficiency (Revenue per Liter)",
    hover_data=["store_name"]
)
st.plotly_chart(fig, use_container_width=True)

top = store.sort_values("efficiency", ascending=False).head(10)
st.subheader("Top 10 Most Efficient Stores")
st.dataframe(top[["store_id", "store_name", "efficiency", "total_revenue"]])
