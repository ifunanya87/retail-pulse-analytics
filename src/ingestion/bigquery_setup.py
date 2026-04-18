from google.cloud import bigquery
from utils.data_utils import get_terraform_config

def create_external_table():
    """
    Configures a BigQuery External Table with Hive Partitioning.
    """
    config = get_terraform_config()
    
    project_id = config["project_id"]
    dataset_id = config["dataset_id"]
    table_name = config["table_name"]
    
    client = bigquery.Client(project=project_id)
    table_id = f"{project_id}.{dataset_id}.{table_name}"
    
    # Wildcard for all parquet files
    parent_folder = f"gs://{config['raw_bucket']}/raw_data/liquor_sales/"
    root_gcs_path = f"{parent_folder}*.parquet"
    
    # Define External Configuration
    external_config = bigquery.ExternalConfig("PARQUET")
    external_config.source_uris = [root_gcs_path]
    
    # Hive Partitioning (reading /year=2021/month=01/ folders as columns)
    hive_options = bigquery.HivePartitioningOptions()
    hive_options.mode = "STRATEGIC"
    hive_options.source_uri_prefix = parent_folder
    hive_options.require_partition_filter = False
    
    external_config.hive_partitioning_options = hive_options

    # Table Creation/Refresh
    table = bigquery.Table(table_id)
    table.external_data_configuration = external_config

    # Force BigQuery to re-scan the GCS paths.
    client.delete_table(table_id, not_found_ok=True)
    client.create_table(table)
    
    return table_id
