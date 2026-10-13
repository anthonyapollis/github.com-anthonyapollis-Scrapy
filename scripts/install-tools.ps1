# Installs Terraform and the Azure CLI on Windows using winget.
# Run in PowerShell. Safe to re-run: tools that are already installed are skipped.
$ErrorActionPreference = "Stop"

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is required. It ships with Windows 10 (1809+) and 11 as 'App Installer'."
}

if (Test-Command terraform) {
    Write-Host "terraform already installed: $(terraform version | Select-Object -First 1)"
} else {
    winget install --id HashiCorp.Terraform --exact --accept-source-agreements --accept-package-agreements
}

if (Test-Command az) {
    Write-Host "az already installed: $(az version --query '\"azure-cli\"' -o tsv)"
} else {
    winget install --id Microsoft.AzureCLI --exact --accept-source-agreements --accept-package-agreements
}

Write-Host ""
Write-Host "Done. Open a NEW PowerShell window so PATH updates, then run:"
Write-Host "  az login"
Write-Host "  infra\azure\deploy.ps1 plan"
