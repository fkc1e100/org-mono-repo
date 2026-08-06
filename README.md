# Organization Fleet Infrastructure & Workload Monorepo (`org-mono-repo`)

Welcome to **`fkc1e100/org-mono-repo`**, the centralized monorepo containing multi-cluster GKE fleet infrastructure configurations, Terraform IaC modules, failure-triage workloads, RBAC policies, and event monitoring scripts.

---

## 🏛️ Monorepo Architecture

```text
org-mono-repo/
├── clusters/
│   ├── gca-gke-2025/          # GCP Project gca-gke-2025 cluster definitions
│   │   ├── cluster-01/
│   │   │   ├── cluster-agent-event-watcher.yaml
│   │   │   └── terraform/     # Modular Terraform IaC (main.tf, variables.tf, outputs.tf)
│   │   ├── complex-01/
│   │   │   ├── README.md
│   │   │   ├── cluster-agent-event-watcher.yaml
│   │   │   └── terraform/     # Mutating Webhook Deadlock cluster IaC
│   │   └── complex-02/
│   └── gca-gke-test/          # GCP Project gca-gke-test cluster definitions
│       ├── cluster-06, 07, 10
│       ├── complex-03/       # Artifact Registry Auth & SA Token Lockout terraform & manifests
│       ├── complex-04/       # PodAntiAffinity + CNI IP Starvation terraform & manifests
│       └── complex-05/       # PD RWO Multi-Attach terraform & manifests
├── manifests/
│   ├── common/               # Fleet base event watchers & LB services
│   ├── labels/               # Fleet namespace labeling standards
│   └── workloads/            # Canonical and complex failure workload manifests
├── rbac/                     # Fleet RBAC roles and cluster role bindings
├── scripts/
│   ├── deploy_fleet_event_watchers.sh   # Deploys kube-agents watcher daemon across fleet
│   └── enforce_broken_state.sh         # Resets fleet workloads to failure states
└── default-deny-netpol.yaml
```

---

## 🏗️ Per-Cluster Terraform Provisioning

Each cluster under `clusters/<project_id>/<cluster_name>/terraform/` contains its dedicated Infrastructure-as-Code declaration:

```text
clusters/<project_id>/<cluster_name>/terraform/
├── main.tf           # GKE Cluster & Node Pool resources
├── variables.tf      # Configurable project, region, zone, machine type & node count
├── outputs.tf        # Cluster endpoint & gcloud get-credentials command
└── terraform.tfvars  # Cluster-specific variable assignments
```

To provision or re-create a cluster:
```bash
cd clusters/gca-gke-2025/complex-01/terraform
terraform init
terraform apply
```

---

## ⚡ Failure Scenarios & Cluster Mapping

| Cluster Name | GCP Project | Domain Failures | Scenario Summary |
|---|---|---|---|
| `cluster-01` | `gca-gke-2025` | Workload | Pod CrashLoopBackOff & Subnet IP Exhaustion |
| `cluster-02` | `gca-gke-2025` | Workload | Private Image Pull Auth Failure |
| `cluster-08` | `gca-gke-2025` | Workload | Spot Instance Obtainability Lockout |
| `cluster-09` | `gca-gke-2025` | Workload | Flex DWS Start Obtainability Timeout |
| `complex-01` | `gca-gke-2025` | Multi-Domain | **Webhook Deadlock & WI Auth**: `MutatingWebhookConfiguration` fails on unreachable backend pod stuck in Workload Identity Secret Manager auth failure. Blocks all cluster pod API requests. |
| `complex-02` | `gca-gke-2025` | Multi-Domain | **NetworkPolicy DNS & GCS Block**: Egress policy drops DNS port 53 & GCP Metadata (`169.254.169.254`), causing host resolution failure & Cloud Storage API timeouts. |
| `complex-03` | `gca-gke-test` | Multi-Domain | **Artifact Registry Auth & RBAC Lockout**: Private container image pull failure from Google Artifact Registry (`us-docker.pkg.dev`), missing automount SA token, and zero RBAC permissions. |
| `complex-04` | `gca-gke-test` | Multi-Domain | **Scheduling Deadlock & CNI IP Starvation**: Strict `podAntiAffinity` on 2-node cluster with 4 vCPU requests + 35 pods exhausting node CNI Pod IP allocation + GCP Internal Load Balancer IP failure. |
| `complex-05` | `gca-gke-test` | Multi-Domain | **PD RWO Storage Lockout & Sysctl Violation**: GCE Persistent Disk ReadWriteOnce multi-attach deadlock across nodes + unprivileged `sysctl` initContainer failure + GCS bucket sync failure. |

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
