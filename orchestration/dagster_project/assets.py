import os
import dlt
import pandas as pd
from dagster import (
    asset, 
    AutoMaterializePolicy, 
    AssetExecutionContext, 
    MonthlyPartitionsDefinition,
    AssetSpec, 
    AssetKey, 
    BackfillPolicy,
    AssetIn,
    LastPartitionMapping,
    Nothing,
)
from dagster_dlt import DagsterDltResource, dlt_assets, DagsterDltTranslator
from dagster_dlt.translator import DltResourceTranslatorData

from src.ingestion.fetch_liquor_data import iowa_liquor_source
from src.ingestion.validate_ingest import get_api_row_count
from src.ingestion.bigquery_setup import create_external_table 



# Partition definition
env_start_str = os.getenv("IOWA_LIQUOR_INITIAL_VALUE").split("T")[0]
env_end_str = os.getenv("IOWA_LIQUOR_END_VALUE").split("T")[0]

iowa_liquor_partitions = MonthlyPartitionsDefinition(
    start_date=env_start_str,
    end_date=env_end_str,
)




# Monitoring asset
@asset(
    partitions_def=iowa_liquor_partitions,
    group_name="monitoring",
    # launch a separate run for every partition
    backfill_policy=BackfillPolicy.multi_run(),
    description="Calculates expected row counts from API using .env boundaries"
)
def iowa_liquor_expected_counts(context: AssetExecutionContext):
    # Partition Info
    dt_str = context.partition_key
    partition_start = pd.to_datetime(dt_str)
    year=partition_start.year
    month=partition_start.month

    # Get the count from the API using the specific window
    expected_count = get_api_row_count(year, month)
    
    # Save to CSV
    output_dir = "data"
    os.makedirs(output_dir, exist_ok=True)
    report_file = os.path.join(output_dir, "reconciliation_report.csv")

    new_data = pd.DataFrame([{
        "partition": dt_str,
        "expected_rows": expected_count,
        "checked_at": pd.Timestamp.now()
    }])
    
    if not os.path.isfile(report_file):
        new_data.to_csv(report_file, index=False)
    else:
        existing = pd.read_csv(report_file)
        existing = existing[existing["partition"] != dt_str]
        pd.concat([existing, new_data]).to_csv(report_file, index=False)
    
    return expected_count


# Ingestion asset factory

# dlt translator
class IowaLiquorTranslator(DagsterDltTranslator):
    def get_asset_spec(self, data: DltResourceTranslatorData) -> AssetSpec:
        # Get the default spec from the base class
        default_spec = super().get_asset_spec(data)
        
        # Override the key and group_name to match your project architecture
        return default_spec.replace_attributes(
            key=AssetKey(f"iowa_{data.resource.name}"), # Forces 'iowa_liquor_sales'
            group_name="bronze"
        )
    

# Define a base pipeline for the decorator to use for metadata
resource_name="liquor_sales"
base_pipeline = dlt.pipeline(
    pipeline_name=f"iowa_{resource_name}_base",
    destination="filesystem",
    dataset_name="raw_data",
)


def make_liquor_asset(resource_name: str):
    
    @dlt_assets(
        dlt_source=iowa_liquor_source(year=2021, month=1).with_resources(resource_name),
        dlt_pipeline=base_pipeline,
        dagster_dlt_translator=IowaLiquorTranslator(),
        partitions_def=iowa_liquor_partitions,
        name=f"iowa_{resource_name}",
        # launch a separate run for every partition
        backfill_policy=BackfillPolicy.multi_run(),
    )
    def dagster_liquor_assets(context: AssetExecutionContext, dlt_res: DagsterDltResource):
        dlt.config["load.truncate_staging_dataset"] = True

        dt_str = context.partition_key
        partition_start = pd.to_datetime(dt_str)
        year=partition_start.year
        month=partition_start.month

        context.log.info(f"Partition {dt_str} fetching data")

        source = iowa_liquor_source(year, month)

        source.resources[resource_name].apply_hints(
            incremental=dlt.sources.incremental(
                cursor_path="date",
                initial_value=partition_start.isoformat()
            )
        )

        # Define pipeline and Run
        pipeline = dlt.pipeline(
            pipeline_name=f"iowa_{resource_name}_{year}_{month:02d}",
            destination="filesystem",
            dataset_name="raw_data",
        )

        yield from dlt_res.run(
            context=context,
            dlt_source=source,
            dlt_pipeline=pipeline,
            loader_file_format="parquet",
        )
    
    return dagster_liquor_assets

# Initialize the parallel assets list
resource_names = ["liquor_sales"]
iowa_liquor_assets_parallel = [make_liquor_asset(res) for res in resource_names]


# Bigquery external table asset
@asset(
    # Allows this asset to run once, only when ingest assets have finished running
    ins={
        "iowa_liquor_sales": AssetIn(
            key_prefix=None,
            partition_mapping=LastPartitionMapping(),
            dagster_type=Nothing,
        )
    },
    group_name="rawgold",
    metadata={
        "database": "BigQuery",
        "refresh_type": "DDL Overwrite"
    },
    description="Refreshed only after ALL months of sales data are loaded."
)
def iowa_liquor_external_table(context: AssetExecutionContext):
    # iowa_liquor_sales is passed in but doesn't need to be used if create_external_table()
    # is a standalone helper function.
    table_id = create_external_table()
    # Record the result back to Dagster so it shows up in the 'Activity' tab
    context.add_output_metadata(
        metadata={
            "table_id": table_id,
            "status": "updated"
        }
    )
    return table_id
