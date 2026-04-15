# Load environment variables
-include .env
export

# Variables
VENV := .venv
PYTHON := uv run python3
TF_DIR := terraform



.PHONY: all info  setup auth-check set-quota enable-apis bootstrap generate_vars init plan apply output run clean-tf clean 



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

GCP_LOG := log/.gcloud_auth.log

auth-check:
	@echo "=== New Auth Session: $$(date) ===" > $(GCP_LOG)
	@echo "" >> $(GCP_LOG)
	@echo "Checking for active GCP session"
	
	@if [ ! -f ~/.config/gcloud/application_default_credentials.json ]; then \
		echo "No ADC session found. Starting login" | tee -a $(GCP_LOG); \
		gcloud auth application-default login --no-launch-browser 2>&1 | tee -a $(GCP_LOG); \
	else \
		echo "Active ADC session found."; \
	fi

	@ACCOUNT=$$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null); \
	if [ -n "$$ACCOUNT" ]; then \
		echo "The active account found is: $$ACCOUNT" >> $(GCP_LOG); \
		echo "Active CLI session found."; \
	else \
		echo "No CLI account active. Starting login" | tee -a $(GCP_LOG); \
		gcloud auth login --no-launch-browser 2>&1 \
			| tee -a $(GCP_LOG) \
			| grep -v "You are now logged in"; \
	fi

	@echo "----------------------------------------------------------------"
	@echo "Auth complete. The logged identity is recorded in $(GCP_LOG)"
	@echo "----------------------------------------------------------------"
	@$(MAKE) --no-print-directory set-quota

set-quota:
	@echo "=== Syncing Config for $(REPO_PROJECT_NAME) ==="
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

bootstrap: setup enable-apis
	@if [ ! -f .bootstrap_done ]; then \
		echo "Creating Terraform State Bucket"; \
		$(PYTHON) bootstrap/bootstrap_state.py && touch .bootstrap_done; \
	fi



# *TERRAFORM*

generate_vars:
	@echo 'project_id         = "$(GCP_PROJECT_ID)"' > $(TF_DIR)/temp.auto.tfvars
	@echo 'region             = "$(GCP_REGION)"' >> $(TF_DIR)/temp.auto.tfvars
	@echo 'tf_service_account = "$(TF_SA_EMAIL)"' >> $(TF_DIR)/temp.auto.tfvars
	@echo 'raw_bucket_name    = "$(GCS_RAW_DATA_BUCKET)"' >> $(TF_DIR)/temp.auto.tfvars
	@echo 'dataset_bronze     = "$(BQ_DATASET_BRONZE)"' >> $(TF_DIR)/temp.auto.tfvars
	@echo 'dataset_silver     = "$(BQ_DATASET_SILVER)"' >> $(TF_DIR)/temp.auto.tfvars
	@echo 'dataset_gold       = "$(BQ_DATASET_GOLD)"' >> $(TF_DIR)/temp.auto.tfvars

init:
	terraform -C $(TF_DIR) init -backend-config="bucket=$(TF_STATE_BUCKET)" -reconfigure

plan: bootstrap generate_vars init
	@echo "Planning Infrastructure Changes"
	terraform -C $(TF_DIR) plan -out=tfplan

apply: plan
	@echo "Applying Infrastructure Changes"
	terraform -C $(TF_DIR) apply "tfplan"
	@rm -f $(TF_DIR)/tfplan $(TF_DIR)/temp.auto.tfvars
	@$(MAKE) --no-print-directory output
	@echo "Infrastructure deployment complete."

output:
	@#echo "Exporting Terraform outputs to file"
	@#terraform -C $(TF_DIR) output -json > infra_outputs.json
	@#echo "Outputs saved to infra_outputs.json"



# *PIPELINE ORCHESTRATION*

run: auth-check
	@echo "Executing Iowa Liquor Pipeline (Impersonating $(TF_SA_EMAIL))"
	@gcloud config set auth/impersonate_service_account $(TF_SA_EMAIL)
	bruin run
	@gcloud config unset auth/impersonate_service_account



# *CLEANUP*

clean-tf:
	rm -rf $(TF_DIR)/.terraform
	rm -f $(TF_DIR)/terraform.tfstate*
	rm -f .bootstrap_done

clean: clean-tf
	rm -rf $(VENV)
	@echo "Environment wiped."
