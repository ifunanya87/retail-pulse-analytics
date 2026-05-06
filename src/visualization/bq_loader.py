import streamlit as st
from google.cloud import bigquery
from utils.config import Config



@st.cache_data(ttl=3600)
def load_query(query):
    client = bigquery.Client(project=Config.PROJECT_ID)
    return client.query(query).to_dataframe()

@st.cache_data(ttl=3600)
def load_all_data():
    """
    Orchestrates data loading with explicit column selection
    """
    
    sales_query = f"""
        SELECT transaction_date, store_id, category_name_standardized, 
               vendor_name_standardized, revenue, volume_liters_sold, avg_unit_price
        FROM `{Config.PROJECT_ID}.{Config.BQ_GOLD}.fct_sales_performance`
    """

    store_query = f"""
        SELECT store_id, store_name, total_revenue, total_volume_liters
        FROM `{Config.PROJECT_ID}.{Config.BQ_GOLD}.agg_store_performance`
    """

    cat_query = f"""
        SELECT sales_month, category_name_standardized, total_revenue, mom_growth_pct
        FROM `{Config.PROJECT_ID}.{Config.BQ_GOLD}.agg_category_monthly_performance`
    """

    vendor_query = f"""
        SELECT vendor_name_standardized, total_revenue, revenue_share
        FROM `{Config.PROJECT_ID}.{Config.BQ_GOLD}.agg_vendor_monthly_performance`
    """

    county_query = f"""
        SELECT sales_month, county, total_revenue, active_stores, revenue_share
        FROM `{Config.PROJECT_ID}.{Config.BQ_GOLD}.agg_county_monthly_performance`
    """

    return {
        "sales_fct": load_query(sales_query),
        "store_mart": load_query(store_query),
        "category_mart": load_query(cat_query),
        "vendor_mart": load_query(vendor_query),
        "county_mart": load_query(county_query),
    }
