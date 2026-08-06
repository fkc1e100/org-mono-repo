# Organization Fleet Infrastructure & Workload Monorepo (`org-mono-repo`)

Welcome to **`fkc1e100/org-mono-repo`**, an enterprise-grade monorepo containing multi-cluster GKE fleet infrastructure modules, Compute Engine (GCE) VM declarations, Config Connector (KCC) GCP infrastructure declarations, OPA Gatekeeper policy-as-code guardrails, reusable Terraform modules, tenant workspace vending definitions, and GitHub Actions CI/CD workflows.

> [!NOTE]
> **GCP Project Portability for Forks**: If you fork this repository, set `export GCP_PROJECT_ID="your-gcp-project-id"` (or `export GCP_PROJECT_2025="..."` and `export GCP_PROJECT_TEST="..."`). All scripts and Terraform modules dynamically adapt to your active GCP project context.

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
│   ├── gce-vm-01-startup-script-failure/      # Legacy Auth VM startup script package failure
│   ├── gce-vm-02-disk-full-journal-lock/      # Audit logger VM boot disk capacity & journald lock
│   ├── complex-gce-01-mig-healthcheck-iam-lockout/ # Managed Instance Group autohealing & IAM lockout
│   ├── complex-gce-02-vpc-firewall-routes-blackhole/ # Edge bastion VPC firewall deny & blackhole route
│   └── complex-gce-03-ops-agent-log-sink-lockout/ # Telemetry exporter Ops Agent IAM logging lockout
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

## 🖥️ Compute Engine (GCE) VM Portfolio (5 Environments)

| GCE Scenario Folder | Target Resource | GCP Project | Target Namespace | Complexity Level | Primary Failure Domain |
|---|---|---|---|---|---|
| [`gce-vm-01-startup-script-failure`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/gce-vm-01-startup-script-failure) | `prod-legacy-auth-vm` | `${GCP_PROJECT_ID}` | `prod-auth` | 🟢 Simple | Startup script package installation failure without egress network access. |
| [`gce-vm-02-disk-full-journal-lock`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/gce-vm-02-disk-full-journal-lock) | `prod-audit-logger-vm` | `${GCP_PROJECT_ID}` | `prod-analytics` | 🟢 Simple | Boot disk unrotated logs hit 100% disk capacity, locking `systemd-journald`. |
| [`complex-gce-01-mig-healthcheck-iam-lockout`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/complex-gce-01-mig-healthcheck-iam-lockout) | `prod-mig-payment-gateway` | `${GCP_PROJECT_ID}` | `prod-payments` | 🔴 Complex | Managed Instance Group (MIG) autohealing loop caused by VM service account missing Secret Manager IAM permissions. |
| [`complex-gce-02-vpc-firewall-routes-blackhole`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/complex-gce-02-vpc-firewall-routes-blackhole) | `prod-edge-bastion-vm` | `${GCP_PROJECT_ID}` | `prod-gateway` | 🔴 Complex | VPC Firewall denies TCP 22/443 ingress while custom static route `0.0.0.0/0` points to a deleted Next Hop Gateway. |
| [`complex-gce-03-ops-agent-log-sink-lockout`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/gce/complex-gce-03-ops-agent-log-sink-lockout) | `prod-finops-exporter-vm` | `${GCP_PROJECT_ID}` | `prod-analytics` | 🔴 Complex | Google Cloud Ops Agent daemon crashes continuously because VM service account lacks `roles/logging.logWriter` IAM permissions. |

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
