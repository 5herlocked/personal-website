FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Install uv as the vscode user
USER vscode
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Add uv to PATH for vscode user
ENV PATH="/home/vscode/.cargo/bin:${PATH}"

# Switch back to root for any additional setup
USER root

# use this Dockerfile to install additional tools you might need, e.g.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
