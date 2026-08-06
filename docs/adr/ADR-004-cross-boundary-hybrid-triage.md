# ADR-004: Cross-Boundary Hybrid GKE/GCE Failure Triage & Root Cause Analysis

## Status
Accepted

## Context
In enterprise production environments, Kubernetes microservices operating on GKE clusters rarely exist in isolation. They depend on legacy infrastructure, Managed Instance Groups (MIGs), database instances, telemetry collectors, and VPC networking infrastructure residing on Google Compute Engine (GCE). 

When evaluating autonomous SRE agents (e.g. Gemini 1.5 Pro / Flash), single-domain failures (such as a simple missing K8s Secret or container OOM) are easily diagnosed. However, **Cross-Boundary Hybrid Failures** present severe diagnostic difficulty because symptoms manifest in Kubernetes while the root cause resides in GCP Compute Engine IAM, VPC Routing, or MIG Autohealing configurations.

---

## 🔬 Complex Cross-Boundary Failure Patterns

### Pattern 1: Webhook API Lockout Cascading from GCE MIG IAM Failure
- **Manifestation in GKE**: Pod creations in `prod-checkout-gateway-11` hang or fail with `Internal error: failed calling webhook fleet-policy-enforcer.kube-agents.io`.
- **Kubernetes View**: The admission webhook pod `admission-webhook-server` is in `CrashLoopBackOff`.
- **Hybrid Dependencies**: 
  1. The webhook container attempts to authenticate with GCP Secret Manager using Workload Identity service account `vault-auth-sa`.
  2. Concurrently, the webhook attempts a health probe check against GCE MIG backend `prod-mig-payment-gateway` (`10.128.0.50:8080`).
  3. The GCE MIG instance template uses GSA `restricted-gsa`, which lacks IAM `roles/secretmanager.secretAccessor` permissions to decrypt `payment-kms-key`.
  4. GCE MIG autohealing health check continuously marks instances as `UNHEALTHY` and triggers endless instance recreations (`STAGING -> UNHEALTHY -> RECREATING`).
- **Triage Challenge**: An agent focusing solely on `kubectl get pods` will attempt to debug Kubernetes webhooks or Secret specs. True remediation requires expanding diagnostic scope to GCP IAM permissions (`gcloud iam service-accounts`) and MIG status (`gcloud compute instance-groups managed describe`).

---

### Pattern 2: VPC Route Blackhole & Firewall Drop Masking as CNI Timeout
- **Manifestation in GKE**: Microservices in `prod-api-router-07` log `Connection timed out` when forwarding egress traffic to edge bastion `prod-edge-bastion-vm`.
- **Kubernetes View**: All Kubernetes `NetworkPolicy` manifests in the namespace allow egress traffic. DNS resolution succeeds.
- **Hybrid Dependencies**:
  1. GCP Compute Firewall rule `block-bastion-ingress` explicitly denies TCP ports 22 and 443 from internal subnet CIDR `10.0.0.0/8`.
  2. GCP Compute Route `blackhole-egress-route` targets `0.0.0.0/0` with next-hop instance `non-existent-nat-gateway`.
- **Triage Challenge**: The agent must inspect GCP VPC firewall rules (`gcloud compute firewall-rules list`) and VPC routing tables (`gcloud compute routes list`) to identify that the egress failure is an infrastructure blackhole outside Kubernetes.

---

## Decision
We formally incorporate cross-boundary hybrid GKE ↔ GCE inter-service dependencies into `org-mono-repo`. Benchmark evaluation suites scoring SRE agents must test the agent's capability to traverse both `kubectl` and `gcloud` API surfaces to reach accurate root cause diagnosis.

## Consequences
- Agents that only inspect Kubernetes resources will fail triage on hybrid scenarios.
- Evaluation metrics will reflect true enterprise SRE capability across multi-domain cloud infrastructure.
