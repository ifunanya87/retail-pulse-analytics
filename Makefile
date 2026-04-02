# Variables
VENV := .venv

.PHONY: all setup install-stack info clean-tf clean-venv clean

# Default action: Just gets the environment ready
all: info setup


# Check System Tools (installed via Dockerfile)
info:
	@echo "=== System Tool Check ==="
	@terraform --version || echo "Terraform not found"
	@bruin --version || echo "Bruin not found"
	@uv --version || echo "uv not found"
	@make --version | head -n 1


# USER/CODESPACE COMMAND: Syncs the environment based on the existing uv.lock
setup:
	@echo "Syncing Python environment from lockfile"
	uv sync
	@echo "Setup complete. Virtual environment is ready in $(VENV)"


# ARCHITECT COMMAND: Defines the stack and generates/updates the uv.lock
install-stack:
	@echo "Installing dbt, BigQuery, and GCP tools"
	uv add dbt-bigquery google-cloud-bigquery google-cloud-storage pandas ipykernel
	uv add --dev pytest sqlfluff
	@echo "New dependencies locked in pyproject.toml and uv.lock."


# CLEANUP COMMANDS
clean-tf:
	rm -rf .terraform
	rm -f tfplan

clean-venv:
	rm -rf $(VENV)

clean: clean-tf clean-venv
	@echo "All temporary artifacts removed."
