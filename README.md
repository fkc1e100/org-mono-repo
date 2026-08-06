# Organization Fleet Infrastructure & Workload Monorepo (`org-mono-repo`)

Welcome to **`fkc1e100/org-mono-repo`**, an enterprise-grade monorepo containing multi-cluster GKE fleet infrastructure modules, Compute Engine (GCE) VM declarations, Config Connector (KCC) GCP infrastructure declarations, OPA Gatekeeper policy-as-code guardrails, reusable Terraform modules, tenant workspace vending definitions, and GitHub Actions CI/CD workflows.

> [!NOTE]
> **GCP Project Portability for Forks**: If you fork this repository, set `export GCP_PROJECT_ID="your-gcp-project-id"` (or `export GCP_PROJECT_2025="..."` and `export GCP_PROJECT_TEST="..."`). All scripts and Terraform modules dynamically adapt to your active GCP project context.

---

## 🔗 Hybrid GKE ↔ GCE Inter-Service Dependencies

In enterprise production architectures, GKE Kubernetes microservices connect to backend GCE VM infrastructure over VPC internal IP addresses. Failure in GCE VM infrastructure cascades into GKE workload health:

```text
GKE Fleet Microservices                  Backend GCE VM Infrastructure
┌────────────────────────────────┐       ┌──────────────────────────────────────┐
│ prod-checkout-gateway-11       │ ─────>│ prod-payment-mig-gateway (10.128.0.50) │
│ (payment-api-gateway)          │       │ (MIG Autohealing IAM Lockout)        │
└────────────────────────────────┘       └──────────────────────────────────────┘
┌────────────────────────────────┐       ┌──────────────────────────────────────┐
│ prod-user-auth-02              │ ─────>│ prod-auth-legacy-vm (10.128.0.25)   │
│ (user-auth-service)            │       │ (Legacy VM Package Installation Fail)│
└────────────────────────────────┘       └──────────────────────────────────────┘
┌────────────────────────────────┐       ┌──────────────────────────────────────┐
│ prod-analytics-store-15        │ ─────>│ prod-finops-telemetry-exporter       │
│ (analytics-worker-service)     │       │ (10.128.0.99 - Ops Agent IAM Crash)  │
└────────────────────────────────┘       └──────────────────────────────────────┘
```

---

## 🚀 Getting Started: GitOps & IaC Provisioning

### Option 1: ArgoCD GitOps Deployment (KCC Declarative Sync)

Because all GCE Compute Engine resources under [`gce/`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce) are declared using Google Cloud Config Connector (KCC) Kubernetes CRDs (`kind: ComputeInstance`, `kind: ComputeRegionInstanceGroupManager`, `kind: ComputeFirewall`), **ArgoCD natively manages and continuously reconciles GCE infrastructure directly from Git**:

```bash
# Apply ArgoCD Application to continuously reconcile GCE infrastructure
kubectl apply -f gce/argocd-app.yaml
```

---

### Option 2: Terraform IaC Provisioning

For teams using Terraform CLI or Terraform Controller:

1. **GKE Cluster Provisioning**:
   ```bash
   cd clusters/prod-core-api-01/terraform
   terraform init
   terraform apply -var="project_id=${GCP_PROJECT_ID}"
   ```

2. **GCE Instance Provisioning**:
   Use the reusable GCE module at [`terraform/modules/gce-instance`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/terraform/modules/gce-instance):
   ```hcl
   module "legacy_auth_vm" {
     source        = "../../terraform/modules/gce-instance"
     project_id    = var.project_id
     instance_name = "prod-legacy-auth-vm"
     machine_type  = "e2-standard-2"
   }
   ```

---

### Option 3: Upstream Sync Pattern (Keeping Forks Updated)

To keep your forked repository continuously synchronized with upstream improvements:

```bash
git remote add upstream https://github.com/fkc1e100/org-mono-repo.git
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
│       ├── gke-cluster/                       # Reusable GKE cluster & nodepool Terraform module
│       └── gce-instance/                      # Reusable GCE VM Compute Engine Terraform module
├── gce/                                       # Compute Engine (GCE) VM & Hybrid Compute Infrastructure
│   ├── argocd-app.yaml                        # ArgoCD GitOps Application for GCE continuous sync
│   ├── prod-auth-legacy-vm/                   # Legacy Auth GCE VM infrastructure & startup script
│   ├── prod-audit-logger-vm/                  # Audit logger GCE VM infrastructure & disk spooling
│   ├── prod-payment-mig-gateway/              # Managed Instance Group template & autohealing health check
│   ├── prod-edge-bastion-gateway/             # Edge bastion GCE VM networking, firewall & route specs
│   └── prod-finops-telemetry-exporter/        # FinOps telemetry exporter GCE VM & Ops Agent config
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
├── clusters/                                  # Fleet Cluster Directories & IaC Configurations
├── manifests/                                 # Kubernetes Manifests & Workload Definitions
├── rbac/                                      # Fleet ClusterRoles & ClusterRoleBindings
├── docs/                                      # Enterprise Documentation & ADRs
│   └── adr/
├── scripts/
│   ├── deploy_fleet_event_watchers.sh        # Deploys kube-agents watcher daemon across GKE fleet
│   ├── deploy_gce_vms_gcloud.sh              # Deploys & resets GCE VM infrastructure via gcloud CLI
│   └── enforce_broken_state.sh              # Resets both GKE fleet workloads & GCE VM states
└── default-deny-netpol.yaml
```

---

## ⚡ Fleet Cluster Portfolio (17 Clusters)

| Cluster Folder Name | GCP Project | Target Workload Manifest | Enterprise Target Namespace | Hybrid GCE Dependency |
|---|---|---|---|---|
| [`prod-core-api-01`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-core-api-01) | `${GCP_PROJECT_ID}` | `payment-processor.yaml` | `prod-payments` | — |
| [`prod-user-auth-02`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-user-auth-02) | `${GCP_PROJECT_ID}` | `user-auth-service.yaml` | `prod-auth` | 🔗 `prod-auth-legacy-vm` (`10.128.0.25`) |
| [`prod-data-pipeline-03`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-data-pipeline-03) | `${GCP_PROJECT_ID}` | `memory-cache-service.yaml` | `prod-caching` | — |
| [`prod-checkout-04`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-checkout-04) | `${GCP_PROJECT_ID}` | `checkout-backend-api.yaml` | `prod-checkout` | — |
| [`prod-storage-db-05`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-storage-db-05) | `${GCP_PROJECT_ID}` | `stateful-postgres-db.yaml` | `prod-databases` | — |
| [`edge-ingress-gateway-06`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/edge-ingress-gateway-06) | `${GCP_PROJECT_ID}` | `frontend-web-gateway.yaml` | `prod-ingress` | — |
| [`prod-api-router-07`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-api-router-07) | `${GCP_PROJECT_ID}` | `api-routing-proxy.yaml` | `prod-gateway` | — |
| [`batch-analytics-08`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/batch-analytics-08) | `${GCP_PROJECT_ID}` | `batch-report-worker.yaml` | `batch-processing` | — |
| [`ai-training-dws-09`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/ai-training-dws-09) | `${GCP_PROJECT_ID}` | `gemma-fine-tuning-job.yaml` | `ai-training` | — |
| [`prod-auto-scaler-10`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-auto-scaler-10) | `${GCP_PROJECT_ID}` | `queue-worker-service.yaml` | `prod-workers` | — |
| [`prod-checkout-gateway-11`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-checkout-gateway-11) | `${GCP_PROJECT_ID}` | `payment-api-gateway.yaml` | `prod-payments` | 🔗 `prod-payment-mig-gateway` (`10.128.0.50`) |
| [`prod-order-processing-12`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-order-processing-12) | `${GCP_PROJECT_ID}` | `checkout-backend-service.yaml` | `prod-checkout` | — |
| [`prod-catalog-sync-13`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-catalog-sync-13) | `${GCP_PROJECT_ID}` | `config-syncer-service.yaml` | `prod-catalog` | — |
| [`prod-ha-payments-14`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-ha-payments-14) | `${GCP_PROJECT_ID}` | `ha-payment-gateway-service.yaml` | `prod-payments` | — |
| [`prod-analytics-store-15`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/prod-analytics-store-15) | `${GCP_PROJECT_ID}` | `analytics-worker-service.yaml` | `prod-analytics` | 🔗 `prod-finops-telemetry-exporter` (`10.128.0.99`) |
| [`ai-inference-gpu-16`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/ai-inference-gpu-16) | `${GCP_PROJECT_ID}` | `llm-batch-inference-job.yaml` | `ai-inference` | — |
| [`hpc-batch-compute-17`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/hpc-batch-compute-17) | `${GCP_PROJECT_ID}` | `hpc-batch-analytics-job.yaml` | `hpc-batch` | — |

---

## 🖥️ Compute Engine (GCE) VM Portfolio (5 Environments)

| GCE Scenario Folder | Target Resource | GCP Project | Target Namespace | Complexity Level | Primary Failure Domain |
|---|---|---|---|---|---|
| [`prod-auth-legacy-vm`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/prod-auth-legacy-vm) | `prod-legacy-auth-vm` | `${GCP_PROJECT_ID}` | `prod-auth` | 🟢 Simple | Startup script package installation failure without egress network access. |
| [`prod-audit-logger-vm`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/prod-audit-logger-vm) | `prod-audit-logger-vm` | `${GCP_PROJECT_ID}` | `prod-analytics` | 🟢 Simple | Boot disk unrotated logs hit 100% disk capacity, locking `systemd-journald`. |
| [`prod-payment-mig-gateway`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/prod-payment-mig-gateway) | `prod-mig-payment-gateway` | `${GCP_PROJECT_ID}` | `prod-payments` | 🔴 Complex | Managed Instance Group (MIG) autohealing loop caused by VM service account missing Secret Manager IAM permissions. |
| [`prod-edge-bastion-gateway`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/prod-edge-bastion-gateway) | `prod-edge-bastion-vm` | `${GCP_PROJECT_ID}` | `prod-gateway` | 🔴 Complex | VPC Firewall denies TCP 22/443 ingress while custom static route `0.0.0.0/0` points to a deleted Next Hop Gateway. |
| [`prod-finops-telemetry-exporter`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/prod-finops-telemetry-exporter) | `prod-finops-exporter-vm` | `${GCP_PROJECT_ID}` | `prod-analytics` | 🔴 Complex | Google Cloud Ops Agent daemon crashes continuously because VM service account lacks `roles/logging.logWriter` IAM permissions. |

---

## 🚀 Operations

### Fleet Watcher Deployment
```bash
./scripts/deploy_fleet_event_watchers.sh
```

### Provision / Reset GCE VM Infrastructure
```bash
./scripts/deploy_gce_vms_gcloud.sh
```

### Reset Entire Fleet & GCE Evaluation State
```bash
./scripts/enforce_broken_state.sh
```
