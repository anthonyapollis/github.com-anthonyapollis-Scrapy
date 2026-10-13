#!/usr/bin/env bash
# Runs the Terraform workflow for this folder.
#
#   ./deploy.sh login     sign in to Azure and select the subscription from terraform.tfvars
#   ./deploy.sh plan      format, validate and preview changes (writes tfplan)
#   ./deploy.sh apply     apply the saved plan
#   ./deploy.sh output    print outputs (the Postgres password is hidden; see below)
#   ./deploy.sh destroy   delete everything in this stack (asks for confirmation)
set -euo pipefail

cd "$(dirname "$0")"

command_name="${1:-plan}"

if [[ ! -f terraform.tfvars ]]; then
  echo "terraform.tfvars not found. Copy terraform.tfvars.example and fill it in." >&2
  exit 1
fi

subscription_id() {
  sed -n 's/^[[:space:]]*subscription_id[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' terraform.tfvars
}

case "$command_name" in
  login)
    az login
    az account set --subscription "$(subscription_id)"
    az account show --query '{name:name, id:id}' -o table
    ;;

  plan)
    terraform init -input=false
    terraform fmt -recursive
    terraform validate
    terraform plan -input=false -out=tfplan
    ;;

  apply)
    [[ -f tfplan ]] || { echo "No tfplan found. Run ./deploy.sh plan first." >&2; exit 1; }
    terraform apply -input=false tfplan
    rm -f tfplan
    terraform output
    echo
    echo "Postgres password: terraform output -raw postgres_admin_password"
    ;;

  output)
    terraform output
    ;;

  destroy)
    terraform destroy
    ;;

  *)
    echo "Usage: $0 {login|plan|apply|output|destroy}" >&2
    exit 1
    ;;
esac
