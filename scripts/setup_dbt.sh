#!/bin/bash

# Load variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found. Please create one with GCP_PROJECT_ID,BQ_DATASET_SILVER,GCP_REGION."
    exit 1
fi

if [ -z "$GCP_PROJECT_ID" ] || [ -z "$BQ_DATASET_SILVER" ] || [ -z "$GCP_REGION" ]; then
        echo "Error: One or more of GCP_PROJECT_ID,BQ_DATASET_SILVER,GCP_REGION are empty in .env"
        exit 1
fi

# Create .dbt directory
mkdir -p ~/.dbt

# Write profiles.yml
cat <<EOF > ~/.dbt/profiles.yml
dbt_project:
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: ${GCP_PROJECT_ID}
      dataset: ${BQ_DATASET_SILVER}
      threads: 4
      location: ${GCP_REGION}
      priority: interactive
  target: dev
EOF

echo "dbt profile created for project: ${GCP_PROJECT_ID}"
