import streamlit as st
import plotly.express as px
from visualization.bq_loader import load_all_data



st.set_page_config(layout="wide")
st.title("Risk Analysis")

data = load_all_data()
store = data["store_mart"]

store["variance"] = store["total_revenue"] - store["total_revenue"].mean()
risk = store[store["variance"] < -20000]

st.metric("High Risk Stores Count", len(risk), delta="-Critical", delta_color="inverse")

fig = px.scatter(
    store,
    x="total_volume_liters",
    y="total_revenue",
    color=store["variance"] < -20000,
    title="Risk Detection (Revenue vs Volume)",
    hover_data=["store_name"],
    color_discrete_map={True: "red", False: "blue"}
)
st.plotly_chart(fig, use_container_width=True)

st.subheader("Underperforming Store List")
st.dataframe(risk[["store_id", "store_name", "total_revenue", "variance"]])
