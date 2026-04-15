import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env
load_dotenv()

class Config:
    # Project Navigation
    BASE_DIR = Path(__file__).resolve().parent.parent.parent
    LOG_DIR = BASE_DIR / "log"
    LOG_DIR.mkdir(exist_ok=True)

    # GCP & Infrastructure
    PROJECT_ID = os.getenv("GCP_PROJECT_ID")
    REGION = os.getenv("GCP_REGION", "us-central1")
    
    # Storage & BigQuery
    TERRAFORM_STATE_BUCKET = os.getenv("TF_STATE_BUCKET", f"{PROJECT_ID}-tfstate")
    RAW_DATA_BUCKET = os.getenv("GCS_RAW_DATA_BUCKET", f"{PROJECT_ID}-liquor-raw")
    
    BQ_BRONZE = os.getenv("BQ_DATASET_BRONZE", "liquor_bronze")
    BQ_SILVER = os.getenv("BQ_DATASET_SILVER", "liquor_silver")
    BQ_GOLD = os.getenv("BQ_DATASET_GOLD", "liquor_gold")

    # Data Ingestion (Socrata API)
    DATA_SOURCE_URL = os.getenv("DATA_SOURCE_URL")
    
    # Validation Logic
    @classmethod
    def validate(cls):
        """Ensures critical settings aren't missing before the pipeline starts."""
        required = ["PROJECT_ID", "DATA_SOURCE_URL"]
        for var in required:
            if not getattr(cls, var):
                raise ImportError(f"CRITICAL: {var} is missing from the .env file.")

# Run validation
Config.validate()
