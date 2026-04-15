import os
import sys
from pathlib import Path
from google.cloud import storage
from google.api_core import exceptions
from google.auth.exceptions import DefaultCredentialsError
from dotenv import load_dotenv
from utils.logger_config import get_logger


# Get the directory path
root_path = Path(__file__).resolve().parent.parent
sys.path.append(str(root_path))
# Logger
logger = get_logger("bootstrap", "bootstrap.log", to_stdout=False)


load_dotenv()



def create_state_bucket():
    bucket_name = os.getenv("TF_STATE_BUCKET")
    project_id = os.getenv("GCP_PROJECT_ID")
    location = os.getenv("GCP_REGION", "us-central1")

    if not bucket_name or not project_id:
        logger.error("Required ENV variables (TF_STATE_BUCKET, GCP_PROJECT_ID) missing.")
        sys.exit(1)
    
    try:
        client = storage.Client(project=project_id)
        bucket = client.lookup_bucket(bucket_name)

        if not bucket:
            logger.info(f"Bucket {bucket_name} not found. Creating")
            bucket = client.create_bucket(bucket_name, location=location)
            logger.info(f"Bucket {bucket_name} created successfully.")
        else:
            logger.info(f"Bucket {bucket_name} exists. Checking security settings")

        # Reconciliation Logic
        updates = False
        if not bucket.versioning_enabled:
            bucket.versioning_enabled = True
            updates = True
            logger.warning("Versioning was disabled. Re-enabling for state safety.")

        if not bucket.iam_configuration.uniform_bucket_level_access_enabled:
            bucket.iam_configuration.uniform_bucket_level_access_enabled = True
            updates = True
            logger.warning("Uniform Bucket-Level Access was disabled. Enforcing now.")

        if updates:
            bucket.patch()
            logger.info("Bucket configuration patched and secured.")
        else:
            logger.info("Bucket is already in the desired state.")

    except DefaultCredentialsError:
        logger.critical("No GCP Credentials found. Run 'gcloud auth application-default login'.")
        sys.exit(1)
    except exceptions.Forbidden as e:
        logger.error(f"Permission denied on project {project_id}. Details: {e}")
        sys.exit(1)
    except Exception as e:
        logger.exception(f"Bootstrap failed due to unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    create_state_bucket()
