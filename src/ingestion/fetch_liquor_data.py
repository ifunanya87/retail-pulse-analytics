import os
import sys
import json
import time
import requests
import pyarrow as pa
import pyarrow.parquet as pq
import pandas as pd
from pathlib import Path
from google.cloud import storage
from dotenv import load_dotenv

from utils.config import Config
from utils.logger_config import get_logger
from ingestion import get_terraform_config


# Logger
logger = get_logger("ingest", "run_time.log", to_stdout=True)

# GCS client
storage_client = storage.Client()


# Parameter Loading (Bruin)
def load_params():
    raw = os.getenv("BRUIN_PARAMETERS")

    if not raw:
        raise ValueError("Missing BRUIN_PARAMETERS from Bruin runtime")

    try:
        params = json.loads(raw)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid BRUIN_PARAMETERS JSON: {e}")

    if "year" not in params or "month" not in params:
        raise ValueError("Parameters must include 'year' and 'month'")

    params.setdefault("limit", 50000)

    return params


# Terraform Config
def load_config():
    tf_outputs = get_terraform_config(tf_dir="./terraform")

    if "pipeline_config" not in tf_outputs:
        raise ValueError("Missing 'pipeline_config' in Terraform outputs")

    config = tf_outputs["pipeline_config"]

    if "raw_bucket" not in config:
        raise ValueError("Missing 'raw_bucket' in Terraform config")

    return config


# Helpers
def build_gcs_path(year: int, month: int) -> str:
    return f"data/year={year}/month={month:02d}/data.parquet"


def get_partition_id(year: int, month: int) -> str:
    return f"{year}-{month:02d}"


def file_exists_in_gcs(bucket_name: str, blob_path: str) -> bool:
    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(blob_path)
        return blob.exists(storage_client)
    except Exception as e:
        logger.error(f"GCS existence check failed for {blob_path}: {e}")
        return False


# Networking
def safe_get(url, retries=3, timeout=60):
    for attempt in range(retries):
        try:
            response = requests.get(url, timeout=timeout)
            response.raise_for_status()
            return response.json()
        except Exception:
            if attempt == retries - 1:
                raise
            time.sleep(2 ** attempt)


# Data Ingestion (Streaming)
def fetch_data(url: str, year: int, month: int, limit: int, logger) -> str:
    base_filter = f"year(date)={year} AND month(date)={month}"
    offset = 0

    temp_file = f"temp_{year}_{month:02d}.parquet.tmp"
    final_file = f"temp_{year}_{month:02d}.parquet"

    writer = None
    schema = None

    # Get expected count
    count_query = f"{url}?$select=count(*)&$where={base_filter}"
    count_resp = safe_get(count_query)
    total_expected = int(count_resp[0]["count"])

    logger.info(f"[{year}-{month:02d}] Target rows: {total_expected}")

    try:
        while True:
            query = (
                f"{url}?$limit={limit}&$offset={offset}"
                f"&$where={base_filter}&$order=:id"
            )

            data = safe_get(query)

            if not data:
                break

            df_chunk = pd.DataFrame(data)
            table = pa.Table.from_pandas(df_chunk)

            if writer is None:
                schema = table.schema
                writer = pq.ParquetWriter(
                    temp_file,
                    schema,
                    compression="snappy"
                )
            else:
                table = table.cast(schema)

            writer.write_table(table)

            offset += len(data)
            progress = (offset / total_expected) * 100 if total_expected else 0

            logger.info(
                f"[{year}-{month:02d}] {offset}/{total_expected} ({progress:.2f}%)"
            )

        if writer:
            writer.close()

    except Exception as e:
        if writer:
            writer.close()
        if os.path.exists(temp_file):
            os.remove(temp_file)
        raise e

    # Atomic rename
    os.rename(temp_file, final_file)

    # Validate
    parquet_file = pq.ParquetFile(final_file)
    actual_rows = parquet_file.metadata.num_rows

    if actual_rows != total_expected:
        logger.warning(
            f"[{year}-{month:02d}] Row mismatch: {actual_rows} vs {total_expected}"
        )

    return final_file


# GCS Upload (File-Based)
def upload_file_to_gcs(local_file: str, bucket_name: str, destination_path: str):
    bucket = storage_client.bucket(bucket_name)

    tmp_path = f"{destination_path}.tmp"
    tmp_blob = bucket.blob(tmp_path)
    final_blob = bucket.blob(destination_path)

    try:
        if final_blob.exists(storage_client):
            raise ValueError(f"File already exists: {destination_path}")

        logger.info(f"Uploading staging: gs://{bucket_name}/{tmp_path}")

        with open(local_file, "rb") as f:
            tmp_blob.upload_from_file(f, content_type="application/octet-stream")

        if not tmp_blob.exists(storage_client):
            raise ValueError("Upload failed")

        logger.info(f"Committing to final path: {destination_path}")

        bucket.copy_blob(tmp_blob, bucket, destination_path)

        if not final_blob.exists(storage_client):
            raise ValueError("Final verification failed")

        tmp_blob.delete()

        logger.info(f"Upload successful: gs://{bucket_name}/{destination_path}")

    except Exception as e:
        logger.error(f"GCS upload failed: {e}")
        raise


# Main Execution
def main():

    config = load_config()
    raw_bucket = config["raw_bucket"]

    url = Config.DATA_SOURCE_URL
    if not url:
        raise ValueError("DATA_SOURCE_URL not set")

    params = load_params()

    year = params["year"]
    month = params["month"]
    limit = params["limit"]

    partition_id = get_partition_id(year, month)
    destination = build_gcs_path(year, month)

    logger.info(f"[{partition_id}] Starting ingestion pipeline")

    if file_exists_in_gcs(raw_bucket, destination):
        logger.info(f"[{partition_id}] Skipping (already exists)")
        return

    try:
        local_file = fetch_data(url, year, month, limit, logger)

        if not os.path.exists(local_file):
            raise ValueError("Local parquet file not created")

        logger.info(f"[{partition_id}] Uploading to GCS")

        upload_file_to_gcs(local_file, raw_bucket, destination)

        os.remove(local_file)

        logger.info(f"[{partition_id}] Ingestion successful")

    except Exception as e:
        logger.error(f"[{partition_id}] Ingestion failed: {e}")
        raise


if __name__ == "__main__":
    main()
