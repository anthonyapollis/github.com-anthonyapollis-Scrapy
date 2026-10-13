# Runs the Terraform workflow for this folder on Windows.
#
#   .\deploy.ps1 login     sign in to Azure and select the subscription from terraform.tfvars
#   .\deploy.ps1 plan      format, validate and preview changes (writes tfplan)
#   .\deploy.ps1 apply     apply the saved plan
#   .\deploy.ps1 output    print outputs
#   .\deploy.ps1 destroy   delete everything in this stack (asks for confirmation)
param(
    [ValidateSet("login", "plan", "apply", "output", "destroy")]
    [string]$Command = "plan"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path terraform.tfvars)) {
    throw "terraform.tfvars not found. Copy terraform.tfvars.example and fill it in."
}

function Get-SubscriptionId {
    $line = Select-String -Path terraform.tfvars -Pattern '^\s*subscription_id\s*=\s*"([^"]+)"' | Select-Object -First 1
    if (-not $line) { throw "subscription_id not set in terraform.tfvars" }
    return $line.Matches[0].Groups[1].Value
}

switch ($Command) {
    "login" {
        az login
        az account set --subscription (Get-SubscriptionId)
        az account show --query "{name:name, id:id}" -o table
    }
    "plan" {
        terraform init -input=false
        terraform fmt -recursive
        terraform validate
        terraform plan -input=false -out=tfplan
    }
    "apply" {
        if (-not (Test-Path tfplan)) { throw "No tfplan found. Run .\deploy.ps1 plan first." }
        terraform apply -input=false tfplan
        Remove-Item tfplan
        terraform output
        Write-Host ""
        Write-Host "Postgres password: terraform output -raw postgres_admin_password"
    }
    "output" { terraform output }
    "destroy" { terraform destroy }
}
