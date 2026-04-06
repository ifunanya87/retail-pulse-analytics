import os
from google.cloud import storage
from dotenv import load_dotenv

load_dotenv()

def create_state_bucket():
    bucket_name = os.getenv("TF_STATE_BUCKET")
    project_id = os.getenv("GCP_PROJECT_ID")
    location = os.getenv("GCP_REGION", "us-central1")
    
    client = storage.Client(project=project_id)
    if not client.lookup_bucket(bucket_name):
        bucket = client.create_bucket(bucket_name, location=location)
        bucket.versioning_enabled = True
        print(f"Created versioned bucket: {bucket_name}")
    else:
        print(f"Bucket {bucket_name} already exists.")

if __name__ == "__main__":
    create_state_bucket()
