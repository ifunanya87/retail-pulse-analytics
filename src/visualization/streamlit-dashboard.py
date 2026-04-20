import streamlit as st
from google.cloud import bigquery
import pandas as pd
import os

import plotly.express as px
from utils.config import Config




# CONFIG & AUTH
PROJECT_ID = Config.PROJECT_ID
DATASET = Config.BQ_GOLD
TABLE = "dm_vendor_performance_reporting"

st.set_page_config(page_title="Iowa Liquor: Vendor Insights", layout="wide")



# DATA ENGINE
@st.cache_data(ttl=3600) # Cache for 1 hour
def load_data():
    client = bigquery.Client(project=PROJECT_ID)
    
    # Explicitly select columns
    query = f"""
        SELECT 
            vendor_name, category_name, partition_month,
            total_sales_revenue, total_refunded_dollars,
            category_dominance_index, return_anomaly_flag,
            return_value_ratio
        FROM `{PROJECT_ID}.{DATASET}.{TABLE}`
    """
    try:
        with st.spinner('Querying BigQuery Gold Layer'):
            df = client.query(query).to_dataframe()
            df["partition_month"] = pd.to_datetime(df["partition_month"])
            return df
    except Exception as e:
        st.error(f"BigQuery query failed: {e}")
        return pd.DataFrame()

df = load_data()


# SIDEBAR FILTERS
st.sidebar.header("Filters")

if not df.empty:
    vendors = st.sidebar.multiselect(
        "Select Vendor",
        options=sorted(df["vendor_name"].unique()),
        default=None
    )

    categories = st.sidebar.multiselect(
        "Select Category",
        options=sorted(df["category_name"].unique()),
        default=None
    )

    # Date filter
    date_range = st.sidebar.date_input(
        "Select Date Range",
        [df["partition_month"].min(), df["partition_month"].max()]
    )

    # Filter logic
    filtered = df.copy()
    if vendors:
        filtered = filtered[filtered["vendor_name"].isin(vendors)]
    if categories:
        filtered = filtered[filtered["category_name"].isin(categories)]

    # Date filtering
    filtered = filtered[
        (filtered["partition_month"] >= pd.to_datetime(date_range[0])) &
        (filtered["partition_month"] <= pd.to_datetime(date_range[1]))
    ]


    # UI LAYOUT: TABS
    st.title("Iowa Liquor Vendor Performance")
    st.markdown(f"**Data Scope:** Jan 2025 - June 2025")

    tab1, tab2, tab3 = st.tabs(["Performance Overview", "Category Trends", "Anomaly Report"])

    with tab1:
        # KPI Calculation
        total_rev = filtered["total_sales_revenue"].sum()
        total_ref = filtered["total_refunded_dollars"].sum()
        # Prevent division by zero
        actual_return_rate = (total_ref / total_rev) if total_rev > 0 else 0
        avg_dominance = filtered["category_dominance_index"].mean()

        col1, col2, col3 = st.columns(3)
        col1.metric("Total Sales Revenue", f"${total_rev:,.0f}")
        col2.metric("Actual Return Rate", f"{actual_return_rate:.2%}")
        col3.metric("Avg Market Share", f"{avg_dominance:.2%}")

        st.subheader("Revenue Trend")
        trend = (
            filtered.groupby("partition_month")["total_sales_revenue"]
            .sum()
            .sort_index()
        )
        st.area_chart(trend)

    with tab2:
        col_left, col_right = st.columns(2)
        
        with col_left:
            st.subheader("Top Categories by Revenue")
            cat_chart = filtered.groupby("category_name")["total_sales_revenue"].sum().sort_values(ascending=False).head(10)
            st.bar_chart(cat_chart)

        with col_right:
            st.subheader("Top Vendors")
            vend_chart = filtered.groupby("vendor_name")["total_sales_revenue"].sum().sort_values(ascending=False).head(10)
            st.bar_chart(vend_chart)

    

    with tab3:
        st.subheader("Statistical Anomaly Distribution")
        
        # Plot the entire dataset 
        if not filtered.empty:
            # Create the scatter plot
            fig = px.scatter(
                filtered,
                x="total_sales_revenue",
                y="return_value_ratio",
                color="return_anomaly_flag",
                hover_name="vendor_name",
                # Adding category to hover data for better context
                hover_data=["category_name", "total_refunded_dollars"],
                labels={
                    "total_sales_revenue": "Revenue ($)",
                    "return_value_ratio": "Return Rate (%)",
                    "return_anomaly_flag": "Classification"
                },
                # Matching color palette
                color_discrete_map={
                    "ANOMALY_HIGH_RETURNS": "#D32F2F", # Red
                    "LOW_RETURNS": "#1976D2",        # Blue
                    "NORMAL": "#E0E0E0"              # Light Grey
                },
                title="Revenue vs. Return Rate by Vendor"
            )

            # Layout
            fig.update_layout(
                showlegend=True,
                xaxis_tickformat='$,.0f',
                yaxis_tickformat='.2%'
            )

            st.plotly_chart(fig, use_container_width=True)

            # Table below for detailed drill-down
            st.divider()
            st.subheader("Detailed Anomaly List")
            anomalies = filtered[filtered["return_anomaly_flag"] != "NORMAL"]
            
            if not anomalies.empty:
                def color_anomalies(val):
                    color = '#D32F2F' if val == 'ANOMALY_HIGH_RETURNS' else '#1976D2' if val == 'LOW_RETURNS' else '#757575'
                    return f'color: {color}; font-weight: bold;' if val == 'ANOMALY_HIGH_RETURNS' else f'color: {color}'

                st.warning(f"Found {len(anomalies)} anomalies requiring investigation.")
                styled_df = anomalies.sort_values("total_sales_revenue", ascending=False).style.map(
                    color_anomalies, 
                    subset=['return_anomaly_flag']
                )
                st.dataframe(styled_df, use_container_width=True)
            else:
                st.success("Operational Health: No anomalies detected.")
else:
    st.warning("No data found. Check your BigQuery connection and Dataset ID.")
    