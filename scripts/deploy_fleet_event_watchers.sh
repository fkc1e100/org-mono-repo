#!/usr/bin/env bash
set -eo pipefail

declare -A CLUSTER_DIRS=(
  ["cluster-01"]="gca-gke-2025:us-central1-a:prod-core-api-01"
  ["cluster-02"]="gca-gke-2025:us-central1-a:prod-user-auth-02"
  ["cluster-03"]="gca-gke-2025:us-central1-a:prod-data-pipeline-03"
  ["cluster-04"]="gca-gke-2025:us-central1-a:prod-checkout-04"
  ["cluster-05"]="gca-gke-2025:us-central1-a:prod-storage-db-05"
  ["cluster-06"]="gca-gke-test:us-central1-a:edge-ingress-gateway-06"
  ["cluster-07"]="gca-gke-test:us-central1-a:prod-api-router-07"
  ["cluster-08"]="gca-gke-2025:us-central1-a:batch-analytics-08"
  ["cluster-09"]="gca-gke-2025:us-central1-a:ai-training-dws-09"
  ["cluster-10"]="gca-gke-test:us-central1-a:prod-auto-scaler-10"
  ["complex-01"]="gca-gke-2025:us-central1-a:prod-checkout-gateway-11"
  ["complex-02"]="gca-gke-2025:us-central1-a:prod-order-processing-12"
  ["complex-03"]="gca-gke-test:us-central1-a:prod-catalog-sync-13"
  ["complex-04"]="gca-gke-test:us-central1-a:prod-ha-payments-14"
  ["complex-05"]="gca-gke-test:us-central1-a:prod-analytics-store-15"
  ["complex-06"]="gca-gke-2025:us-central1-a:ai-inference-gpu-16"
  ["complex-07"]="gca-gke-test:us-central1-a:hpc-batch-compute-17"
)

for c in "${!CLUSTER_DIRS[@]}"; do
  IFS=":" read -r proj zone dir <<< "${CLUSTER_DIRS[$c]}"
  echo "=== Deploying kube-agents event watcher to $c ($proj / $zone / $dir) ==="
  gcloud container clusters get-credentials "$c" --zone "$zone" --project "$proj"
  
  if [ -f "clusters/$dir/cluster-agent-event-watcher.yaml" ]; then
    kubectl apply -f "clusters/$dir/cluster-agent-event-watcher.yaml"
  fi
done

echo "=== Fleet Event Watcher Deployment Complete ==="
