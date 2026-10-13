#!/usr/bin/env bash
# Installs Terraform and the Azure CLI on Linux or macOS.
# Safe to re-run: tools that are already installed are skipped.
set -euo pipefail

TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.9.8}"

have() { command -v "$1" >/dev/null 2>&1; }

install_terraform() {
  if have terraform; then
    echo "terraform already installed: $(terraform version | head -1)"
    return
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    have brew || { echo "Homebrew is required: https://brew.sh" >&2; exit 1; }
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    return
  fi

  local arch
  case "$(uname -m)" in
    x86_64)  arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac

  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/terraform.zip" \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${arch}.zip"
  have unzip || sudo apt-get install -y unzip
  unzip -o "$tmp/terraform.zip" -d "$tmp" >/dev/null
  sudo install -m 0755 "$tmp/terraform" /usr/local/bin/terraform
  rm -rf "$tmp"
  echo "installed $(terraform version | head -1)"
}

install_azure_cli() {
  if have az; then
    echo "az already installed: $(az version --query '"azure-cli"' -o tsv)"
    return
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    brew install azure-cli
  else
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  fi
  echo "installed az $(az version --query '"azure-cli"' -o tsv)"
}

install_terraform
install_azure_cli

echo
echo "Done. Next: az login, then infra/azure/deploy.sh plan"
