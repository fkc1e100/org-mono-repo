# Organization Fleet Infrastructure & Workload Monorepo (`org-mono-repo`)

Welcome to **`fkc1e100/org-mono-repo`**, an enterprise-grade monorepo containing multi-cluster GKE fleet infrastructure modules, Config Connector (KCC) GCP infrastructure declarations, OPA Gatekeeper policy-as-code guardrails, reusable Terraform modules, tenant workspace vending definitions, and GitHub Actions CI/CD workflows with automated review bots.

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
│   ├── cluster-01-ip-exhaustion-crashloop/
│   ├── cluster-02-private-registry-auth-fail/
│   ├── cluster-03-oomkilled-memory-limit/
│   ├── cluster-04-missing-secret-key-crash/
│   ├── cluster-05-pvc-unbound-storageclass/
│   ├── cluster-06-ingress-tls-cert-missing/
│   ├── cluster-07-liveness-probe-failure/
│   ├── cluster-08-spot-obtainability-lockout/
│   ├── cluster-09-flex-dws-obtainability-timeout/
│   ├── cluster-10-hpa-cpu-metric-missing/
│   ├── complex-01-webhook-deadlock-wi-auth/
│   ├── complex-02-dns-netpol-gcs-block/
│   ├── complex-03-gar-auth-sa-token-lockout/
│   ├── complex-04-pod-affinity-cni-ip-starvation/
│   ├── complex-05-pd-rwo-multiattach-sysctl/
│   ├── complex-06-spot-gpu-stockout-fallback/
│   └── complex-07-cpu-stockout-compute-class/
├── manifests/                                 # Kubernetes Manifests & Workload Definitions
│   ├── common/                                # Base fleet event watchers & loadbalancer services
│   ├── labels/                                # Fleet namespace labeling standards
│   └── workloads/                             # Canonical and complex failure workload manifests
├── rbac/                                      # Fleet ClusterRoles & ClusterRoleBindings
│   ├── role.yaml
│   └── rolebinding.yaml
├── docs/                                      # Enterprise Documentation & ADRs
│   └── adr/
│       ├── ADR-001-monorepo-layout.md
│       ├── ADR-002-config-connector-adoption.md
│       └── ADR-003-custom-compute-classes-for-gpu-stockout.md
├── scripts/
│   ├── deploy_fleet_event_watchers.sh        # Deploys kube-agents watcher daemon across fleet
│   └── enforce_broken_state.sh              # Resets fleet workloads to failure states
└── default-deny-netpol.yaml                   # Cluster-wide default deny egress/ingress NetPol
```

---

## ⚡ Fleet Scenarios Summary (17 Clusters)

| Cluster Directory Name | GCP Project | Primary Failure Domain | Failure Workload Manifest | Scenario Summary |
|---|---|---|---|---|
| [`cluster-01-ip-exhaustion-crashloop`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-01-ip-exhaustion-crashloop) | `gca-gke-2025` | Workload | `wl-01-crashloop.yaml` | Pod CrashLoopBackOff & Subnet IP Exhaustion |
| [`cluster-02-private-registry-auth-fail`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-02-private-registry-auth-fail) | `gca-gke-2025` | Workload | `wl-02-private-image-auth-fail.yaml` | Private Image Pull Auth Failure |
| [`cluster-03-oomkilled-memory-limit`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-03-oomkilled-memory-limit) | `gca-gke-2025` | Workload | `wl-03-oomkilled.yaml` | Container Memory Limit Exceeded (`OOMKilled` Exit Code 137) |
| [`cluster-04-missing-secret-key-crash`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-04-missing-secret-key-crash) | `gca-gke-2025` | Workload | `wl-04-missing-secret-key.yaml` | Missing Secret Key in Env (`CreateContainerConfigError`) |
| [`cluster-05-pvc-unbound-storageclass`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-05-pvc-unbound-storageclass) | `gca-gke-2025` | Storage | `wl-05-pvc-unbound.yaml` | PersistentVolumeClaim Unbound (Non-Existent StorageClass) |
| [`cluster-06-ingress-tls-cert-missing`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-06-ingress-tls-cert-missing) | `gca-gke-test` | Ingress | `wl-06-ingress-tls-missing.yaml` | Ingress Routing Failure due to Missing TLS Certificate Secret |
| [`cluster-07-liveness-probe-failure`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-07-liveness-probe-failure) | `gca-gke-test` | Workload | `wl-07-liveness-probe-fail.yaml` | Liveness Probe Port Misconfig & Continuous Container Restarts |
| [`cluster-08-spot-obtainability-lockout`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-08-spot-obtainability-lockout) | `gca-gke-2025` | Workload | `wl-08-spot-obtainability-failure.yaml` | Spot Instance Obtainability Lockout |
| [`cluster-09-flex-dws-obtainability-timeout`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-09-flex-dws-obtainability-timeout) | `gca-gke-2025` | Workload | `wl-09-flex-obtainability-timeout.yaml` | Flex DWS Start Obtainability Timeout |
| [`cluster-10-hpa-cpu-metric-missing`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-10-hpa-cpu-metric-missing) | `gca-gke-test` | Autoscaling | `wl-10-hpa-metric-missing.yaml` | HorizontalPodAutoscaler Target Missing CPU Resource Requests |
| [`complex-01-webhook-deadlock-wi-auth`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-01-webhook-deadlock-wi-auth) | `gca-gke-2025` | Multi-Domain | `complex-01-webhook-deadlock.yaml` | Webhook Deadlock & Secret Manager Workload Identity Auth Failure |
| [`complex-02-dns-netpol-gcs-block`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-02-dns-netpol-gcs-block) | `gca-gke-2025` | Multi-Domain | `complex-02-dns-netpol-failure.yaml` | NetPol Egress Isolation dropping DNS port 53 & GCP Metadata |
| [`complex-03-gar-auth-sa-token-lockout`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-03-gar-auth-sa-token-lockout) | `gca-gke-test` | Multi-Domain | `complex-03-rbac-token-lockout.yaml` | Artifact Registry Pull Fail, disabled SA token automount, zero RBAC |
| [`complex-04-pod-affinity-cni-ip-starvation`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-04-pod-affinity-cni-ip-starvation) | `gca-gke-test` | Multi-Domain | `complex-04-cni-affinity-exhaustion.yaml` | Strict `podAntiAffinity` + CNI IP allocation exhaustion + ILB Failure |
| [`complex-05-pd-rwo-multiattach-sysctl`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-05-pd-rwo-multiattach-sysctl) | `gca-gke-test` | Multi-Domain | `complex-05-storage-init-deadlock.yaml` | PersistentDisk RWO multi-attach deadlock + unprivileged `sysctl` |
| [`complex-06-spot-gpu-stockout-fallback`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-06-spot-gpu-stockout-fallback) | `gca-gke-2025` | Compute | `complex-06-gpu-stockout-autoscaling.yaml` | Spot A100 GPU stockout via `a100-gpu-class` ComputeClass |
| [`complex-07-cpu-stockout-compute-class`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-07-cpu-stockout-compute-class) | `gca-gke-test` | Compute | `complex-07-cpu-stockout-compute-class.yaml` | High-core 56-vCPU Spot stockout via `cpu-hpc-compute-class` ComputeClass |

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
