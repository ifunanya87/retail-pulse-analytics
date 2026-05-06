import pandas as pd
from sklearn.cluster import KMeans
import plotly.graph_objects as go



def pareto_chart(df, category_col, value_col):
    df = df.sort_values(value_col, ascending=False)
    df["cum_pct"] = df[value_col].cumsum() / df[value_col].sum()

    fig = go.Figure()
    fig.add_bar(x=df[category_col], y=df[value_col], name="Revenue")
    fig.add_scatter(
        x=df[category_col],
        y=df["cum_pct"],
        name="Cumulative %",
        yaxis="y2"
    )

    fig.update_layout(
        yaxis2=dict(overlaying='y', side='right', tickformat=".0%")
    )
    return fig



def hhi_index(df, value_col):
    """Calculates Herfindahl-Hirschman Index to measure market concentration."""
    share = df[value_col] / df[value_col].sum()
    return (share ** 2).sum()



def cluster_stores(df):
    """Store segmentation using revenue and volume."""
    features = ["total_revenue", "total_volume_liters"]
    X = df[features].fillna(0)
    kmeans = KMeans(n_clusters=3, random_state=42)
    df["cluster"] = kmeans.fit_predict(X).astype(str) # Cast to string for discrete color mapping
    return df
