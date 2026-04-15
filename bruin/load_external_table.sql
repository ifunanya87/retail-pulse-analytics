name: load.iowa_liquor_external
type: bq.sql
depends:
  - ingest_iowa_liquor
---

CREATE OR REPLACE EXTERNAL TABLE `{{ project_id }}.bronze.liquor_raw_external_table`
WITH PARTITION COLUMNS (
    year,
    month
)
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://{{ raw_bucket }}/data/*/*/*.parquet'],
    hive_partition_uri_prefix = 'gs://{{ raw_bucket }}/data',
    require_partition_filter = true
);
