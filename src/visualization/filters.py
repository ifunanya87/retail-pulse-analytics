import streamlit as st
import pandas as pd



def apply_filters(data):
    fct = data["sales_fct"]
    st.sidebar.header("Filters")

    # Use transaction_date from fct_sales_performance
    min_date = pd.to_datetime(fct["transaction_date"]).min()
    max_date = pd.to_datetime(fct["transaction_date"]).max()

    date_range = st.sidebar.date_input("Date Range", [min_date, max_date])

    category = st.sidebar.multiselect(
        "Category",
        options=sorted(data["category_mart"]["category_name_standardized"].unique())
    )

    vendor = st.sidebar.multiselect(
        "Vendor",
        options=sorted(data["vendor_mart"]["vendor_name_standardized"].unique())
    )

    return {
        "date_range": date_range,
        "category": category,
        "vendor": vendor
    }
