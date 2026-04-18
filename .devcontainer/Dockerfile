# Use the stable Python 3.11 tag
FROM mcr.microsoft.com/devcontainers/python:3.11-bullseye

# Install uv (Pinned version)
COPY --from=ghcr.io/astral-sh/uv:0.11.3 /uv /uvx /bin/

# Prevent hardlink errors across different filesystems
ENV UV_LINK_MODE=copy
# Ensure the python output is sent straight to terminal)
ENV PYTHONUNBUFFERED=1

# Install system dependencies + Clean up to keep image lean
RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    apt-transport-https \
    ca-certificates \
    gnupg \
    # 1. Add Google Cloud public key
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    # 2. Add the gcloud repository
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    # 3. Install gcloud (Pinned to current stable version)
    && apt-get update && apt-get install -y google-cloud-cli=563.0.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER vscode

# Set workdir
WORKDIR /workspace

# Default command
CMD ["bash"]
