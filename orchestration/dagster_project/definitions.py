from dagster import (
    Definitions, 
    define_asset_job, 
    multiprocess_executor, 
    AssetSelection
)
from dagster_dlt import DagsterDltResource

from src.utils.config import Config
from .assets import iowa_liquor_expected_counts, iowa_liquor_assets_parallel, iowa_liquor_external_table



# Define a job that selects our parallel assets
liquor_job = define_asset_job(
    name="iowa_liquor_parallel_job",
    # iowa_liquor_external_table not added becos it will be auto materialized
    selection=AssetSelection.assets(iowa_liquor_expected_counts, *iowa_liquor_assets_parallel).downstream(),
    executor_def=multiprocess_executor.configured({
        "max_concurrent": 2
    })
)


defs = Definitions(
    assets=[iowa_liquor_expected_counts, iowa_liquor_external_table] + iowa_liquor_assets_parallel,
    jobs=[liquor_job],
    resources={
        "dlt_res": DagsterDltResource(),
    },
)




# # Current_file
# current_file_path = Path(__file__).resolve()

# # Root folder
# ROOT_DIR = current_file_path.parent.parent.parent

# # Combine with the dbt path
# DBT_PROJECT_DIR = ROOT_DIR / "src" / "transformation" / "dbt"

# # Verify the path exists
# if not DBT_PROJECT_DIR.joinpath("dbt_project.yml").exists():
#     raise FileNotFoundError(
#         f"Could not find dbt_project.yml at {DBT_PROJECT_DIR}. "
#         "Check your directory nesting!"
#     )

