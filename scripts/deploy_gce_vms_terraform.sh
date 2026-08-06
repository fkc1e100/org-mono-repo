#!/usr/bin/env bash
set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || echo "gca-gke-2025")}"

echo "============================================================"
echo " Deploying GCE VM Compute Infrastructure via Terraform IaC"
echo " Target GCP Project: ${PROJECT_ID}"
echo "============================================================"

cd "${REPO_ROOT}/gce/terraform"
terraform init
terraform apply -auto-approve -var="project_id=${PROJECT_ID}"

echo "============================================================"
echo " Terraform GCE VM Deployment Complete."
echo "============================================================"
