import json
from pathlib import Path


def get_terraform_config():
    """
    Locates infra_outputs.json by navigating up from this file's directory
    to the project root.
    """
    # Get the directory 
    current_file_dir = Path(__file__).resolve().parent
    
    # Project root
    # src/utils/ -> src/ -> project_root/
    project_root = current_file_dir.parent.parent
    output_path = project_root / "infra_outputs.json"

    if not output_path.exists():
        raise FileNotFoundError(f"Config not found at {output_path.absolute()}")

    with open(output_path, "r") as f:
        tf_outputs = json.load(f)

    try:
        config = {
            "project_id": tf_outputs["project_id"]["value"],
            "raw_bucket": tf_outputs["raw_bucket_name"]["value"],
            "dataset_id": tf_outputs["bronze_dataset_id"]["value"],
            "table_name": "iowa_liquor_sales_external_raw"
        }
        return config
    except KeyError as e:
        raise KeyError(f"Key {e} not found in {output_path}. Ensure Terraform Apply finished.")
    


def build_soql_query(year: int, month: int, is_count: bool = False) -> str:
    """Constructs a SoQL query for a specific month."""
    start_date = f"{year}-{month:02d}-01T00:00:00"
    
    if month == 12:
        end_date = f"{year + 1}-01-01T00:00:00"
    else:
        end_date = f"{year}-{month + 1:02d}-01T00:00:00"
        
    # Handle the 'SELECT' clause based on the goal
    select_clause = "SELECT count(*)" if is_count else "SELECT *"
    
    # Using backticks for 'date' to avoid reserved keyword errors
    return f"{select_clause} WHERE `date` >= '{start_date}' AND `date` < '{end_date}'"
    