# Load environment variables
-include .env
export

# Variables
VENV := .venv
PYTHON := uv run python3

.PHONY: all setup auth-check enable-apis bootstrap plan apply run info clean-tf clean generate_vars



# Default: Ensure infra is up and data is ready
all: info setup apply run



# *ENVIRONMENT & TOOLS*

info:
	@echo "=== System Tool Check ==="
	@terraform --version | head -n 1 || echo "Terraform not found"
	@gcloud --version | head -n 1 || echo "Google Cloud CLI not found"
	@bruin --version || echo "Bruin not found"
	@uv --version || echo "uv not found"

setup: info
	@echo "Syncing Python environment"
	uv sync
	@echo "Setup complete. Virtual environment ready."



# *CLOUD FOUNDATION*

# Define a hidden log file
GCP_LOG := .gcloud_auth.log

auth-check:
	@echo "=== New Auth Session: $$(date) ===" > $(GCP_LOG)
	@echo "Checking for active GCP session"
	@# Check/Login for ADC (Terraform/Python)
	@if [ ! -f ~/.config/gcloud/application_default_credentials.json ]; then \
		echo "No ADC session found. Starting login"; \
		gcloud auth application-default login --no-launch-browser 2>&1 | tee -a $(GCP_LOG); \
	else \
		echo "Active ADC session found."; \
	fi

	@# Check/Login for CLI (gcloud commands)
	@ACCOUNT=$$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null); \
	if [ -n "$$ACCOUNT" ]; then \
		echo "The active account found is: $$ACCOUNT" >> $(GCP_LOG) 2>&1; \
		echo "Active CLI session found."; \
	else \
		echo "No CLI account active. Starting login..." | tee -a $(GCP_LOG); \
		gcloud auth login --no-launch-browser 2>&1 | tee -a $(GCP_LOG); \
	fi
	@$(MAKE) set-quota

set-quota:
	@echo "=== Syncing Config for $(REPO_PROJECT_NAME) ==="
	@echo "Logging to $(GCP_LOG)"
	@gcloud config set project $(GCP_PROJECT_ID) >> $(GCP_LOG) 2>&1
	@gcloud auth application-default set-quota-project $(GCP_PROJECT_ID) >> $(GCP_LOG) 2>&1

enable-apis: auth-check
	@echo "Enabling Bootstrap APIs"
	@gcloud services enable \
		cloudresourcemanager.googleapis.com \
		serviceusage.googleapis.com \
		iamcredentials.googleapis.com
	@echo "APIs enabled. Waiting 30s for propagation"
	@sleep 30

# Intelligent bootstrap: only runs if the marker file doesn't exist
bootstrap: setup enable-apis
	@if [ ! -f .bootstrap_done ]; then \
		echo "Creating Terraform State Bucket"; \
		$(PYTHON) bootstrap/bootstrap_state.py && touch .bootstrap_done; \
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
run: auth-check
	@echo "Executing Iowa Liquor Pipeline (Impersonating $(TF_SA_EMAIL))"
	@gcloud config set auth/impersonate_service_account $(TF_SA_EMAIL)
	bruin run
	@# Unset impersonation after the run to avoid local confusion
	@gcloud config unset auth/impersonate_service_account



# *CLEANUP*

clean-tf:
	rm -rf terraform/.terraform
	rm -f terraform/terraform.tfstate*
	rm -f .bootstrap_done

clean: clean-tf
	rm -rf $(VENV)
	@echo "Environment wiped."
