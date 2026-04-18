import requests
import pandas as pd
from utils.config import Config
from utils.data_utils import build_soql_query


def get_api_row_count(year: int, month: int) -> int:
    """
    Get expected row count from SODA 3.0 using the exact 
    start and end timestamps used by ingestion.
    """
    url = Config.DATA_SOURCE_URL
    
    # Build the query using the specific timestamps
    count_query = build_soql_query(year, month, is_count=True)
    
    headers = {
        "Content-Type": "application/json",
        "X-App-Token": Config.SODA_APP_TOKEN
    }

    payload = {
        "query": count_query,
        "includeSynthetic": False
    }

    # In src/ingestion/validate_ingest.py
    response = requests.post(
        url, 
        json=payload, 
        headers=headers, 
        timeout=30
    )
    
    if response.status_code != 200:
        print(f"SODA Error: {response.text}")
    else:
        print(f"SODA success: {response.text}")

    response.raise_for_status()
    data = response.json()
    
    # Return the first result from the array of dicts
    return int(data[0]["count"])
