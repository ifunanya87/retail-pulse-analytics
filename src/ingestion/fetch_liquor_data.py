import dlt
import os
import requests
from typing import Any, Iterator
from tenacity import retry, stop_after_attempt, wait_exponential
from utils.config import Config
from utils.data_utils import build_soql_query



# truncate staging_staging schema produced by dlt together with dagster by default
# dlt.config["load.truncate_staging_dataset"] = True


@retry(stop=stop_after_attempt(3), wait=wait_exponential(min=2, max=10))
def fetch_soda_v3(query_str: str, page_number: int, page_size: int) -> Any:
    """
    SODA 3.0 POST implementation. 
    Uses a JSON payload to define the query and pagination.
    """
    # Endpoint follows the /api/v3/views/{id}/query.json pattern
    url = f"https://data.iowa.gov/api/v3/views/m3tr-qhgy/query.json"
    
    headers = {
        "Content-Type": "application/json",
        "X-App-Token": Config.SODA_APP_TOKEN
    }

    # This matches the 'curl --json' structure from the documentation
    payload = {
        "query": query_str,
        "page": {
            "pageNumber": page_number,
            "pageSize": page_size
        },
        "includeSynthetic": False
    }

    response = requests.post(url, json=payload, headers=headers)
    response.raise_for_status()
    return response.json()


# "liquor_sales" will hold the main data amongst all the folders created by dlt in destination
@dlt.resource(name="liquor_sales", write_disposition="merge", primary_key="invoice_line_no")
def iowa_liquor_resource(year: int, month: int) -> Iterator[dict]:
    """
    Iterative fetcher using SODA 3.0 page-based pagination.
    """
    page_size = 5000 # Standard stable page size
    current_page = 1
    query_str = build_soql_query(year, month, is_count=False)

    while True:
        batch = fetch_soda_v3(query_str, current_page, page_size)

        if not batch or len(batch) == 0:
            break

        # Yielding the list allows DLT to process the batch efficiently
        yield batch

        current_page += 1

@dlt.source
def iowa_liquor_source(year: int, month: int):
    return iowa_liquor_resource(year=year, month=month)
