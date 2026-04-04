# Load environment variables
-include .env
export

# Variables
VENV := .venv
PYTHON := uv run python3

.PHONY: all setup bootstrap plan apply run info clean-tf clean

# Default: Ensure infra is up and data is ready
all: info setup apply run

# *ENVIRONMENT & TOOLS*

info:
	@echo "=== System Tool Check ==="
	@terraform --version || echo "Terraform not found"
	@bruin --version || echo "Bruin not found"
	@uv --version || echo "uv not found"

setup:
	@echo "Syncing Python environment"
	uv sync
	@echo "Setup complete. Virtual environment ready."

# *CLOUD FOUNDATION*

# Intelligent bootstrap: only runs if the marker file doesn't exist
bootstrap: setup
	@if [ ! -f .bootstrap_done ]; then \
		echo "Creating Terraform State Bucket"; \
		$(PYTHON) bootstrap_state.py && touch .bootstrap_done; \
	fi

# Helper to generate temporary tfvars from .env
generate_vars:
	@echo 'project_id         = "$(GCP_PROJECT_ID)"' > terraform/temp.auto.tfvars
	@echo 'region             = "$(GCP_REGION)"' >> terraform/temp.auto.tfvars
	@echo 'tf_service_account = "$(TF_SA_EMAIL)"' >> terraform/temp.auto.tfvars
	@echo 'raw_bucket_name    = "$(GCS_RAW_DATA_BUCKET)"' >> terraform/temp.auto.tfvars
	@echo 'dataset_bronze     = "$(BQ_DATASET_BRONZE)"' >> terraform/temp.auto.tfvars
	@echo 'dataset_silver     = "$(BQ_DATASET_SILVER)"' >> terraform/temp.auto.tfvars
	@echo 'dataset_gold       = "$(BQ_DATASET_GOLD)"' >> terraform/temp.auto.tfvars


# Generates the execution plan
plan: bootstrap generate_vars
	@echo "Planning Infrastructure Changes"
	cd terraform && terraform init -backend-config="bucket=$(TF_STATE_BUCKET)"
	cd terraform && terraform plan -var-file="temp.auto.tfvars" -out=tfplan

# Applies the PREVIOUSLY generated plan
apply: plan
	@echo "Applying Infrastructure Changes"
	cd terraform && terraform apply "tfplan"
	@rm -f terraform/tfplan terraform/temp.auto.tfvars
	@echo "Infrastructure deployment complete."

# *PIPELINE ORCHESTRATION*

# Triggers Bruin to handle Ingestion -> GCS -> BigQuery -> dbt
run:
	@echo "Executing Iowa Liquor Pipeline (2021-2026)"
	bruin run

# *CLEANUP*

clean-tf:
	rm -rf terraform/.terraform
	rm -f terraform/terraform.tfstate*
	rm -f .bootstrap_done

clean: clean-tf
	rm -rf $(VENV)
	@echo "Environment wiped."
