# Organization Fleet Infrastructure & Workload Monorepo (`org-mono-repo`)

Welcome to **`fkc1e100/org-mono-repo`**, the centralized monorepo containing multi-cluster GKE fleet infrastructure configurations, Config Connector (KCC) GCP infrastructure declarations, Terraform IaC modules, failure-triage workloads, RBAC policies, and event monitoring scripts.

---

## 🏛️ Monorepo Architecture

```text
org-mono-repo/
├── gcp-infrastructure/                        # Config Connector (KCC) GCP Resources as Code
│   ├── database/                              # CloudSQL SQLInstance & SQLDatabase KCC CRDs
│   ├── iam/                                   # Workload Identity IAMServiceAccount & IAMPolicyBinding KCC CRDs
│   ├── kms/                                   # Customer-Managed Encryption Keys (KMSKeyRing, KMSCryptoKey)
│   ├── networking/                            # ComputeNetwork VPC & ComputeSubnetwork KCC CRDs
│   └── storage/                               # StorageBucket & Access Control KCC CRDs
├── clusters/                                  # Specific Fleet Cluster Directories & Terraform IaC
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
├── manifests/
│   ├── common/                               # Fleet base event watchers & LB services
│   ├── labels/                               # Fleet namespace labeling standards
│   └── workloads/                            # Canonical and complex failure workload manifests
├── rbac/                                     # Fleet RBAC roles and cluster role bindings
├── scripts/
│   ├── deploy_fleet_event_watchers.sh        # Deploys kube-agents watcher daemon across fleet
│   └── enforce_broken_state.sh              # Resets fleet workloads to failure states
└── default-deny-netpol.yaml
```

---

## ⚡ Failure Scenarios & Cluster Mapping

| Cluster Folder Name | GCP Project | Domain Failures | Scenario Summary |
|---|---|---|---|
| [`cluster-01-ip-exhaustion-crashloop`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-01-ip-exhaustion-crashloop) | `gca-gke-2025` | Workload | Pod CrashLoopBackOff & Subnet IP Exhaustion |
| [`cluster-02-private-registry-auth-fail`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-02-private-registry-auth-fail) | `gca-gke-2025` | Workload | Private Container Image Pull Authentication Failure |
| [`cluster-03-oomkilled-memory-limit`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-03-oomkilled-memory-limit) | `gca-gke-2025` | Workload | Container Memory Limit Exceeded (`OOMKilled` Exit Code 137) |
| [`cluster-04-missing-secret-key-crash`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-04-missing-secret-key-crash) | `gca-gke-2025` | Workload | Missing Secret Key in Env (`CreateContainerConfigError`) |
| [`cluster-05-pvc-unbound-storageclass`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-05-pvc-unbound-storageclass) | `gca-gke-2025` | Storage | PersistentVolumeClaim Pending due to Non-Existent StorageClass |
| [`cluster-06-ingress-tls-cert-missing`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-06-ingress-tls-cert-missing) | `gca-gke-test` | Ingress | Ingress Routing Failure due to Missing TLS Certificate Secret |
| [`cluster-07-liveness-probe-failure`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-07-liveness-probe-failure) | `gca-gke-test` | Workload | Liveness Probe Port Misconfiguration & Continuous Container Restarts |
| [`cluster-08-spot-obtainability-lockout`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-08-spot-obtainability-lockout) | `gca-gke-2025` | Workload | Spot Instance Obtainability Lockout |
| [`cluster-09-flex-dws-obtainability-timeout`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-09-flex-dws-obtainability-timeout) | `gca-gke-2025` | Workload | Flex DWS Start Obtainability Timeout |
| [`cluster-10-hpa-cpu-metric-missing`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/cluster-10-hpa-cpu-metric-missing) | `gca-gke-test` | Autoscaling | HorizontalPodAutoscaler Target Deployment Missing CPU Resource Requests |
| [`complex-01-webhook-deadlock-wi-auth`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-01-webhook-deadlock-wi-auth) | `gca-gke-2025` | Multi-Domain | **Webhook Deadlock & WI Auth**: `MutatingWebhookConfiguration` fails on unreachable backend pod stuck in Workload Identity Secret Manager auth failure. |
| [`complex-02-dns-netpol-gcs-block`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-02-dns-netpol-gcs-block) | `gca-gke-2025` | Multi-Domain | **NetworkPolicy DNS & GCS Block**: Egress policy drops DNS port 53 & GCP Metadata (`169.254.169.254`). |
| [`complex-03-gar-auth-sa-token-lockout`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-03-gar-auth-sa-token-lockout) | `gca-gke-test` | Multi-Domain | **Artifact Registry Auth & SA Token Lockout**: Artifact Registry pull fail, disabled SA token automount, missing RBAC. |
| [`complex-04-pod-affinity-cni-ip-starvation`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-04-pod-affinity-cni-ip-starvation) | `gca-gke-test` | Multi-Domain | **Scheduling Deadlock & CNI Starvation**: Strict `podAntiAffinity` + 35 pods exhausting CNI IP allocation + ILB failure. |
| [`complex-05-pd-rwo-multiattach-sysctl`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-05-pd-rwo-multiattach-sysctl) | `gca-gke-test` | Multi-Domain | **PD RWO Storage Lockout & Sysctl Violation**: PersistentDisk ReadWriteOnce multi-attach deadlock + unprivileged `sysctl`. |
| [`complex-06-spot-gpu-stockout-fallback`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-06-spot-gpu-stockout-fallback) | `gca-gke-2025` | Compute | **Spot GPU Stockout & ComputeClass Fallback**: `a100-gpu-class` ComputeClass scale-up fails with `ZONE_RESOURCE_POOL_EXHAUSTED`. |
| [`complex-07-cpu-stockout-compute-class`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/clusters/complex-07-cpu-stockout-compute-class) | `gca-gke-test` | Compute | **High-Core vCPU Spot Stockout & ComputeClass**: Workload requests `cpu-hpc-compute-class` (56 vCPUs on `c2-standard-60` Spot). GKE Cluster Autoscaler scale-up fails with `ZONE_RESOURCE_POOL_EXHAUSTED` in `us-central1-a`. |

---

## 🏗️ Per-Cluster Terraform Provisioning

Each cluster under `clusters/<cluster_dir>/terraform/` contains its dedicated Infrastructure-as-Code declaration:

```text
clusters/<cluster_dir>/terraform/
├── main.tf           # GKE Cluster & Node Pool resources
├── variables.tf      # Configurable project, region, zone, machine type & node count
├── outputs.tf        # Cluster endpoint & gcloud get-credentials command
└── terraform.tfvars  # Cluster-specific variable assignments
```

---

## 🚀 Usage & Operations

### Deploying Fleet Event Watchers
```bash
./scripts/deploy_fleet_event_watchers.sh
```

### Enforcing Fleet Failure States
```bash
./scripts/enforce_broken_state.sh
```
