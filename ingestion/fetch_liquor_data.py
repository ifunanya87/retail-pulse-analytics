import os
import sys
import json
import tempfile
import requests
import pandas as pd
from io import BytesIO
from pathlib import Path
from google.cloud import storage
from dotenv import load_dotenv

from ingestion import get_terraform_config
from utils.logger_config import get_logger


# Path + logger
root_path = Path(__file__).resolve().parent.parent
sys.path.append(str(root_path))

logger = get_logger("ingest", "run_time.log", to_stdout=True)


# Client
storage_client = storage.Client()


# Parameter Loading (bruin entrypoint)
def load_params():
    """
    Loads parameters injected by Bruin via environment variable.

    Expected format:
    BRUIN_PARAMETERS='{"year": 2023, "month": 5, "limit": 50000}'
    """
    raw = os.getenv("BRUIN_PARAMETERS")

    if not raw:
        raise ValueError("Missing BRUIN_PARAMETERS from Bruin runtime")

    try:
        params = json.loads(raw)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid BRUIN_PARAMETERS JSON: {e}")

    # Required fields
    if "year" not in params or "month" not in params:
        raise ValueError("Parameters must include 'year' and 'month'")

    # Default fallback
    params.setdefault("limit", 50000)

    return params


# Terraform config
def load_config():
    tf_outputs = get_terraform_config(tf_dir="./terraform")

    if "pipeline_config" not in tf_outputs:
        raise ValueError("Missing 'pipeline_config' in Terraform outputs")

    config = tf_outputs["pipeline_config"]

    if "raw_bucket" not in config:
        raise ValueError("Missing 'raw_bucket' in Terraform config")

    return config


# GCS path builder
def build_gcs_path(year: int, month: int) -> str:
    return f"data/year={year}/month={month:02d}/data.parquet"


def get_partition_id(year: int, month: int) -> str:
    return f"{year}-{month:02d}"


# Idempotency check for GCS
def file_exists_in_gcs(bucket_name: str, blob_path: str) -> bool:
    """
    Checks if file exists in GCS.

    Production note:
    For large-scale systems, replace this with a manifest table (BigQuery).
    """
    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(blob_path)

        return blob.exists(storage_client)

    except Exception as e:
        logger.error(f"GCS existence check failed for {blob_path}: {e}")
        return False


# Data ingestion
def fetch_data(url: str, limit: int, year: int, month: int) -> pd.DataFrame:
    """
    Fetch filtered data from Socrata API.
    """

    query = f"{url}?$limit={limit}&$where=year(date)={year} AND month(date)={month}"

    logger.info(f"[{year}-{month:02d}] Fetching data")

    response = requests.get(query, timeout=60)
    response.raise_for_status()

    data = response.json()

    if not data:
        raise ValueError(f"No data returned for {year}-{month:02d}")

    return pd.DataFrame(data)


# GCS upload
def upload_to_gcs(df: pd.DataFrame, bucket_name: str, destination_path: str):
    """
    Safe GCS ingestion pattern:
    temp file → upload (.tmp) → verify → copy → verify → delete tmp
    """

    bucket = storage_client.bucket(bucket_name)
    final_blob = bucket.blob(destination_path)

    tmp_path = f"{destination_path}.tmp"
    tmp_blob = bucket.blob(tmp_path)

    local_tmp_file = None

    try:
        # Prevent overwrite
        if final_blob.exists(storage_client):
            raise ValueError(f"Final destination already exists: {destination_path}")

        # Write local temp file
        with tempfile.NamedTemporaryFile(suffix=".parquet", delete=False) as f:
            local_tmp_file = f.name

        df.to_parquet(local_tmp_file, index=False)

        if os.path.getsize(local_tmp_file) == 0:
            raise ValueError("Empty parquet file generated")

        # Upload to staging (.tmp)
        logger.info(f"Uploading staging object: gs://{bucket_name}/{tmp_path}")

        with open(local_tmp_file, "rb") as f:
            tmp_blob.upload_from_file(f, content_type="application/octet-stream")

        if not tmp_blob.exists(storage_client):
            raise ValueError("Staging upload failed")

        # Copy to final
        logger.info(f"Committing to final path: {destination_path}")

        bucket.copy_blob(tmp_blob, bucket, destination_path)

        # Verify final object
        if not final_blob.exists(storage_client):
            raise ValueError("Final copy verification failed")

        # Cleanup staging
        tmp_blob.delete()

        logger.info(f"Upload committed successfully: gs://{bucket_name}/{destination_path}")

    except Exception as e:
        logger.error(f"Atomic upload failed for {destination_path}: {e}")
        raise

    finally:
        if local_tmp_file and os.path.exists(local_tmp_file):
            try:
                os.remove(local_tmp_file)
            except Exception as cleanup_err:
                logger.warning(f"Temp cleanup failed: {cleanup_err}")

# Main execution
def main():
    load_dotenv()

    config = load_config()
    raw_bucket = config["raw_bucket"]

    url = os.getenv("DATA_SOURCE_URL")
    if not url:
        raise ValueError("DATA_SOURCE_URL not set")

    params = load_params()

    year = params["year"]
    month = params["month"]
    limit = params["limit"]

    partition_id = get_partition_id(year, month)
    destination = build_gcs_path(year, month)

    logger.info(f"[{partition_id}] Starting ingestion pipeline")

    # Idempotency check
    if file_exists_in_gcs(raw_bucket, destination):
        logger.info(f"[{partition_id}] Skipping (already exists in GCS)")
        return

    # Ingestion
    try:
        df = fetch_data(url, limit, year, month)

        if df.empty:
            logger.warning(f"[{partition_id}] No data returned")
            return

        logger.info(f"[{partition_id}] Uploading to gs://{raw_bucket}/{destination}")

        upload_to_gcs(df, raw_bucket, destination)

        logger.info(f"[{partition_id}] Ingestion successful")

    except Exception as e:
        logger.error(f"[{partition_id}] Ingestion failed: {e}")
        raise



if __name__ == "__main__":
    main()
