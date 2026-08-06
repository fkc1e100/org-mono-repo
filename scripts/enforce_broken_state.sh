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
echo " Starting Fleet Reset to Canonical Evaluation State"
echo " Target GCP Project: ${GCP_PROJECT_ID}"
echo "============================================================"

PROJ_2025="${GCP_PROJECT_2025:-${GCP_PROJECT_ID}}"
PROJ_TEST="${GCP_PROJECT_TEST:-${GCP_PROJECT_ID}}"

# -------------------------------------------------------------------
# 1. Enforce GKE Fleet Workloads
# -------------------------------------------------------------------
declare -A CLUSTER_DIRS=(
  ["cluster-01"]="${PROJ_2025}:us-central1-a:prod-core-api-01"
  ["cluster-02"]="${PROJ_2025}:us-central1-a:prod-user-auth-02"
  ["cluster-03"]="${PROJ_2025}:us-central1-a:prod-data-pipeline-03"
  ["cluster-04"]="${PROJ_2025}:us-central1-a:prod-checkout-04"
  ["cluster-05"]="${PROJ_2025}:us-central1-a:prod-storage-db-05"
  ["cluster-06"]="${PROJ_TEST}:us-central1-a:edge-ingress-gateway-06"
  ["cluster-07"]="${PROJ_TEST}:us-central1-a:prod-api-router-07"
  ["cluster-08"]="${PROJ_2025}:us-central1-a:batch-analytics-08"
  ["cluster-09"]="${PROJ_2025}:us-central1-a:ai-training-dws-09"
  ["cluster-10"]="${PROJ_TEST}:us-central1-a:prod-auto-scaler-10"
  ["complex-01"]="${PROJ_2025}:us-central1-a:prod-checkout-gateway-11"
  ["complex-02"]="${PROJ_2025}:us-central1-a:prod-order-processing-12"
  ["complex-03"]="${PROJ_TEST}:us-central1-a:prod-catalog-sync-13"
  ["complex-04"]="${PROJ_TEST}:us-central1-a:prod-ha-payments-14"
  ["complex-05"]="${PROJ_TEST}:us-central1-a:prod-analytics-store-15"
  ["complex-06"]="${PROJ_2025}:us-central1-a:ai-inference-gpu-16"
  ["complex-07"]="${PROJ_TEST}:us-central1-a:hpc-batch-compute-17"
)

for c in "${!CLUSTER_DIRS[@]}"; do
  IFS=":" read -r proj zone dir <<< "${CLUSTER_DIRS[$c]}"
  echo "=== Enforcing failing evaluation state on GKE $c ($proj / $zone / $dir) ==="
  gcloud container clusters get-credentials "$c" --zone "$zone" --project "$proj"
  
  case "$c" in
    cluster-01)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/payment-processor.yaml" || true
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/network-daemon.yaml" || true
      ;;
    cluster-02)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/user-auth-service.yaml" || true
      ;;
    cluster-03)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/memory-cache-service.yaml" || true
      ;;
    cluster-04)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/checkout-backend-api.yaml" || true
      ;;
    cluster-05)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/stateful-postgres-db.yaml" || true
      ;;
    cluster-06)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/frontend-web-gateway.yaml" || true
      ;;
    cluster-07)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/api-routing-proxy.yaml" || true
      ;;
    cluster-08)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/batch-report-worker.yaml" || true
      ;;
    cluster-09)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/gemma-fine-tuning-job.yaml" || true
      ;;
    cluster-10)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/queue-worker-service.yaml" || true
      ;;
    complex-01)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/payment-api-gateway.yaml" || true
      ;;
    complex-02)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/checkout-backend-service.yaml" || true
      ;;
    complex-03)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/config-syncer-service.yaml" || true
      ;;
    complex-04)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/ha-payment-gateway-service.yaml" || true
      ;;
    complex-05)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/analytics-worker-service.yaml" || true
      ;;
    complex-06)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/llm-batch-inference-job.yaml" || true
      ;;
    complex-07)
      kubectl apply -f "${REPO_ROOT}/manifests/workloads/hpc-batch-analytics-job.yaml" || true
      ;;
  esac
done

# -------------------------------------------------------------------
# 2. Enforce GCE VM Compute Infrastructure Declarations
# -------------------------------------------------------------------
echo "=== Enforcing GCE VM Compute Infrastructure Declarations ==="
if [ -d "${REPO_ROOT}/gce" ]; then
  find "${REPO_ROOT}/gce" -name "*.yaml" -exec kubectl apply -f {} \; || true
fi

echo "============================================================"
echo " ✔ Fleet reset completed successfully."
echo "============================================================"
