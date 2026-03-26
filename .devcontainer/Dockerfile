FROM mcr.microsoft.com/devcontainers/python:3.11

# Install Terraform
ARG TERRAFORM_VERSION=1.6.3
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y terraform=${TERRAFORM_VERSION}*

# Install Docker CLI, curl, unzip, and git
RUN apt-get update && apt-get install -y docker.io curl unzip git

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Install Bruin CLI
RUN curl -LsSf https://getbruin.com/install/cli | sh

# Set workdir
WORKDIR /workspace

# Default command
CMD ["bash"]
