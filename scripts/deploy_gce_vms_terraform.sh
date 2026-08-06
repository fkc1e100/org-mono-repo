#!/usr/bin/env bash
set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# -------------------------------------------------------------------
# Intelligent GCP Project Resolution
# -------------------------------------------------------------------
resolve_gcp_project() {
  if [ -n "${GCP_PROJECT_ID}" ]; then
    echo "✔ Using GCP_PROJECT_ID from environment: ${GCP_PROJECT_ID}"
    return
  fi

  DETECTED_PROJ="$(gcloud config get-value project 2>/dev/null || echo "")"
  
  if [ -t 0 ] && [ -n "${DETECTED_PROJ}" ]; then
    read -p "Detected active GCP Project '${DETECTED_PROJ}'. Use this project? [Y/n]: " choice
    case "$choice" in
      [nN][oO]|[nN])
        read -p "Enter target GCP Project ID: " INPUT_PROJ
        export GCP_PROJECT_ID="${INPUT_PROJ}"
        ;;
      *)
        export GCP_PROJECT_ID="${DETECTED_PROJ}"
        ;;
    esac
  elif [ -n "${DETECTED_PROJ}" ]; then
    export GCP_PROJECT_ID="${DETECTED_PROJ}"
  else
    if [ -t 0 ]; then
      read -p "Enter target GCP Project ID: " INPUT_PROJ
      export GCP_PROJECT_ID="${INPUT_PROJ}"
    else
      export GCP_PROJECT_ID="gca-gke-2025"
    fi
  fi
  echo "✔ Resolved GCP Project ID: ${GCP_PROJECT_ID}"
}

resolve_gcp_project

echo "============================================================"
echo " Deploying GCE VM Compute Infrastructure via Terraform IaC"
echo " Target GCP Project: ${GCP_PROJECT_ID}"
echo "============================================================"

cd "${REPO_ROOT}/gce/terraform"
terraform init
terraform apply -auto-approve -var="project_id=${GCP_PROJECT_ID}"

echo "============================================================"
echo " ✔ Terraform GCE VM Deployment Complete."
echo "============================================================"
