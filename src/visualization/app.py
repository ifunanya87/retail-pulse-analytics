import streamlit as st
from visualization.bq_loader import load_all_data
from visualization.filters import apply_filters




st.set_page_config(layout="wide")

st.title("Retail Intelligence System")

data = load_all_data()

filters = apply_filters(data)

st.success("Use the sidebar to navigate dashboards")
