# Organization Fleet Infrastructure & Workload Monorepo (`org-mono-repo`)

Welcome to **`fkc1e100/org-mono-repo`**, an enterprise-grade monorepo containing multi-cluster GKE fleet infrastructure modules, Compute Engine (GCE) VM declarations, Config Connector (KCC) GCP infrastructure declarations, OPA Gatekeeper policy-as-code guardrails, reusable Terraform modules, tenant workspace vending definitions, and GitHub Actions CI/CD workflows.

> [!NOTE]
> **GCP Project Portability for Forks**: If you fork this repository, set `export GCP_PROJECT_ID="your-gcp-project-id"` (or `export GCP_PROJECT_2025="..."` and `export GCP_PROJECT_TEST="..."`). All scripts and Terraform modules dynamically adapt to your active GCP project context.

---

## 🚀 Getting Started: Fork & Sync Guide

### Option 1: Standard Fork & Provisioning

1. **Fork & Clone**:
   Fork `https://github.com/fkc1e100/org-mono-repo` on GitHub and clone locally:
   ```bash
   git clone https://github.com/<your-github-username>/org-mono-repo.git
   cd org-mono-repo
   ```

2. **Set GCP Authentication & Target Project**:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   export GCP_PROJECT_ID="your-gcp-project-id"
   ```

3. **Provision Fleet Cluster Infrastructure (Terraform)**:
   ```bash
   cd clusters/prod-core-api-01/terraform
   terraform init
   terraform apply -var="project_id=${GCP_PROJECT_ID}"
   ```

4. **Deploy Event Watchers & Apply Fleet Workloads**:
   ```bash
   ./scripts/deploy_fleet_event_watchers.sh
   ./scripts/enforce_broken_state.sh
   ```

---

### Option 2: Upstream Sync Pattern (Keeping Forks Updated)

To keep your forked repository continuously synchronized with upstream improvements:

1. **Configure Upstream Remote**:
   ```bash
   git remote add upstream https://github.com/fkc1e100/org-mono-repo.git
   ```

2. **Sync Upstream Updates**:
   ```bash
   git fetch upstream
   git checkout main
   git rebase upstream/main
   git push origin main --force
   ```

---

## 🏛️ Enterprise Monorepo Architecture

```text
org-mono-repo/
├── .github/                                    # Enterprise CI/CD & Automated Review Bots
│   ├── dependabot.yml                         # Dependabot automated dependency review bot
│   ├── workflows/
│   │   ├── terraform-ci.yaml                  # Terraform format, tflint, and validation checks
│   │   ├── policy-scan.yaml                   # Conftest policy-as-code validation on PRs
│   │   ├── trivy-security-bot.yaml            # Trivy automated security review bot
│   │   ├── pr-title-linter.yaml               # Semantic PR title linter bot
│   │   └── stale-bot.yaml                     # Automated stale PR and issue triage bot
│   └── CODEOWNERS                             # Granular PR approval enforcement
├── .pre-commit-config.yaml                    # Local workstation git pre-commit hooks
├── terraform/                                 # Standardized Reusable IaC Core
│   └── modules/
│       └── gke-cluster/                       # Modular GKE cluster, Workload Identity & nodepool IaC
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── gce/                                       # Compute Engine (GCE) VM & Hybrid Compute Infrastructure
│   ├── gce-vm-01-startup-script-failure/      # Legacy Auth VM startup script package failure
│   ├── gce-vm-02-disk-full-journal-lock/      # Audit logger VM boot disk capacity & journald lock
│   ├── complex-gce-01-mig-healthcheck-iam-lockout/ # Managed Instance Group autohealing & IAM lockout
│   └── complex-gce-02-vpc-firewall-routes-blackhole/ # Edge bastion VPC firewall deny & blackhole route
├── gcp-infrastructure/                        # Config Connector (KCC) GCP Resources as Code
│   ├── database/                              # CloudSQL SQLInstance & SQLDatabase KCC CRDs
│   ├── iam/                                   # Workload Identity IAMServiceAccount & IAMPolicyBinding
│   ├── kms/                                   # Customer-Managed Encryption Keys (KMSKeyRing, KMSCryptoKey)
│   ├── networking/                            # ComputeNetwork VPC & ComputeSubnetwork KCC CRDs
│   └── storage/                               # StorageBucket & Access Control KCC CRDs
├── governance/                                # Policy-as-Code & Security Guardrails
│   └── gatekeeper/constraints/
│       ├── disallow-privileged-containers.yaml
│       ├── enforce-allowed-registries.yaml
│       └── require-finops-labels.yaml
├── tenants/                                   # Multi-Tenancy Self-Service Workspace Vending
│   ├── team-analytics/                        # Namespace, ResourceQuota & GPU allocation
│   └── team-checkout/                         # Namespace, ResourceQuota & PodSecurity Restricted
├── clusters/                                  # Fleet Cluster Directories & IaC Configurations
│   ├── prod-core-api-01/
│   ├── prod-user-auth-02/
│   ├── prod-data-pipeline-03/
│   ├── prod-checkout-04/
│   ├── prod-storage-db-05/
│   ├── edge-ingress-gateway-06/
│   ├── prod-api-router-07/
│   ├── batch-analytics-08/
│   ├── ai-training-dws-09/
│   ├── prod-auto-scaler-10/
│   ├── prod-checkout-gateway-11/
│   ├── prod-order-processing-12/
│   ├── prod-catalog-sync-13/
│   ├── prod-ha-payments-14/
│   ├── prod-analytics-store-15/
│   ├── ai-inference-gpu-16/
│   └── hpc-batch-compute-17/
├── manifests/                                 # Kubernetes Manifests & Workload Definitions
│   ├── common/                                # Base fleet event watchers & loadbalancer services
│   ├── labels/                                # Fleet namespace labeling standards
│   └── workloads/                             # Production business domain workload manifests
├── rbac/                                      # Fleet ClusterRoles & ClusterRoleBindings
├── docs/                                      # Enterprise Documentation & ADRs
│   └── adr/
├── scripts/
│   ├── deploy_fleet_event_watchers.sh        # Deploys kube-agents watcher daemon across fleet
│   └── enforce_broken_state.sh              # Resets fleet workloads to evaluation states
└── default-deny-netpol.yaml
```

---

## ⚡ Fleet Cluster Portfolio (17 Clusters)

| Cluster Folder Name | GCP Project | Target Workload Manifest | Enterprise Target Namespace |
|---|---|---|---|
| [`prod-core-api-01`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-core-api-01) | `${GCP_PROJECT_ID}` | `payment-processor.yaml` | `prod-payments` |
| [`prod-user-auth-02`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-user-auth-02) | `${GCP_PROJECT_ID}` | `user-auth-service.yaml` | `prod-auth` |
| [`prod-data-pipeline-03`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-data-pipeline-03) | `${GCP_PROJECT_ID}` | `memory-cache-service.yaml` | `prod-caching` |
| [`prod-checkout-04`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-checkout-04) | `${GCP_PROJECT_ID}` | `checkout-backend-api.yaml` | `prod-checkout` |
| [`prod-storage-db-05`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-storage-db-05) | `${GCP_PROJECT_ID}` | `stateful-postgres-db.yaml` | `prod-databases` |
| [`edge-ingress-gateway-06`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/edge-ingress-gateway-06) | `${GCP_PROJECT_ID}` | `frontend-web-gateway.yaml` | `prod-ingress` |
| [`prod-api-router-07`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-api-router-07) | `${GCP_PROJECT_ID}` | `api-routing-proxy.yaml` | `prod-gateway` |
| [`batch-analytics-08`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/batch-analytics-08) | `${GCP_PROJECT_ID}` | `batch-report-worker.yaml` | `batch-processing` |
| [`ai-training-dws-09`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/ai-training-dws-09) | `${GCP_PROJECT_ID}` | `gemma-fine-tuning-job.yaml` | `ai-training` |
| [`prod-auto-scaler-10`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-auto-scaler-10) | `${GCP_PROJECT_ID}` | `queue-worker-service.yaml` | `prod-workers` |
| [`prod-checkout-gateway-11`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-checkout-gateway-11) | `${GCP_PROJECT_ID}` | `payment-api-gateway.yaml` | `prod-payments` |
| [`prod-order-processing-12`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-order-processing-12) | `${GCP_PROJECT_ID}` | `checkout-backend-service.yaml` | `prod-checkout` |
| [`prod-catalog-sync-13`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-catalog-sync-13) | `${GCP_PROJECT_ID}` | `config-syncer-service.yaml` | `prod-catalog` |
| [`prod-ha-payments-14`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-ha-payments-14) | `${GCP_PROJECT_ID}` | `ha-payment-gateway-service.yaml` | `prod-payments` |
| [`prod-analytics-store-15`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-analytics-store-15) | `${GCP_PROJECT_ID}` | `analytics-worker-service.yaml` | `prod-analytics` |
| [`ai-inference-gpu-16`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/ai-inference-gpu-16) | `${GCP_PROJECT_ID}` | `llm-batch-inference-job.yaml` | `ai-inference` |
| [`hpc-batch-compute-17`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/hpc-batch-compute-17) | `${GCP_PROJECT_ID}` | `hpc-batch-analytics-job.yaml` | `hpc-batch` |

---

## 🖥️ Compute Engine (GCE) VM Portfolio (4 Environments)

| GCE Scenario Folder | Target Resource | GCP Project | Target Namespace | Complexity Level | Primary Failure Domain |
|---|---|---|---|---|---|
| [`gce-vm-01-startup-script-failure`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/gce-vm-01-startup-script-failure) | `prod-legacy-auth-vm` | `${GCP_PROJECT_ID}` | `prod-auth` | 🟢 Simple | Startup Script & Package Dependency Egress |
| [`gce-vm-02-disk-full-journal-lock`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/gce-vm-02-disk-full-journal-lock) | `prod-audit-logger-vm` | `${GCP_PROJECT_ID}` | `prod-analytics` | 🟢 Simple | Boot Disk Capacity & Systemd Journal Lock |
| [`complex-gce-01-mig-healthcheck-iam-lockout`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/complex-gce-01-mig-healthcheck-iam-lockout) | `prod-mig-payment-gateway` | `${GCP_PROJECT_ID}` | `prod-payments` | 🔴 Complex | MIG Autohealing Loop & IAM Secret Manager Lockout |
| [`complex-gce-02-vpc-firewall-routes-blackhole`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/complex-gce-02-vpc-firewall-routes-blackhole) | `prod-edge-bastion-vm` | `${GCP_PROJECT_ID}` | `prod-gateway` | 🔴 Complex | VPC Firewall Deny & Static Route Blackhole |

---

## 🚀 Operations

### Fleet Watcher Deployment
```bash
./scripts/deploy_fleet_event_watchers.sh
```

### Reset Fleet State
```bash
./scripts/enforce_broken_state.sh
```
