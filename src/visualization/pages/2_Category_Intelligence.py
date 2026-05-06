import streamlit as st
import pandas as pd
import plotly.express as px
from visualization.bq_loader import load_all_data



st.set_page_config(layout="wide")
st.title("Category Intelligence")

data = load_all_data()
df = data["category_mart"]

# Cast to datetime and sort
df['sales_month'] = pd.to_datetime(df['sales_month'])
df = df.sort_values(['sales_month', 'total_revenue'], ascending=[True, False])

# KPI Header
top_cat = df.groupby("category_name_standardized")["total_revenue"].sum().idxmax()
avg_growth = df["mom_growth_pct"].mean()

c1, c2 = st.columns(2)
c1.metric("Top Performing Category", top_cat)
c2.metric("Avg MoM Growth", f"{avg_growth:.2%}")

# CATEGORY FILTERING
# Select specific categories or default to the Top 5
all_cats = df["category_name_standardized"].unique().tolist()
selected_cats = st.multiselect("Select Categories to Compare", all_cats, default=all_cats[:5])
filtered_df = df[df["category_name_standardized"].isin(selected_cats)]

fig = px.line(
    filtered_df,
    x="sales_month",
    y="total_revenue",
    color="category_name_standardized",
    title="Category Revenue Trends (Top Selected)",
    markers=True # Markers helps identify actual data points vs interpolations
)
st.plotly_chart(fig, use_container_width=True)

# Heatmap
pivot = df.pivot_table(
    index="category_name_standardized",
    columns="sales_month",
    values="mom_growth_pct"
).sort_index(axis=1)

fig2 = px.imshow(pivot, title="Category MoM Growth Heatmap", color_continuous_scale="RdYlGn")
st.plotly_chart(fig2, use_container_width=True)
