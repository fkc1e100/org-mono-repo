# Operational Blueprint: Monorepo Sync, Argo CD GitOps & Keyless Terraform CI/CD

This operational blueprint documents the step-by-step procedure to sync `org-mono-repo` to a target infrastructure repository (e.g. `gke-fleet-iac`), configure Argo CD GitOps monitoring, and set up keyless GitHub Actions CI/CD for Terraform using GCP Workload Identity Federation.

---

## 📖 Complete Operational Blueprint

```text
┌──────────────────────────────────────┐       1. Repository Mirror       ┌──────────────────────────────────────┐
│  fkc1e100/org-mono-repo (READ-ONLY)  │ ───────────────────────────────> │      fkc1e100/gke-fleet-iac        │
└──────────────────────────────────────┘                                  └──────────────────────────────────────┘
                                                                               │                      │
                                             2. Argo CD GitOps                 │                      │ 3. Keyless TF CI/CD
                                                (No KCC)                       ▼                      ▼
                                                        ┌─────────────────────────────┐        ┌────────────────────────────┐
                                                        │  Argo CD (kcc-management)   │        │ GitHub Actions TF Runner   │
                                                        │  • gke-fleet-workloads      │        │  • Workload Identity Auth  │
                                                        │  • gke-fleet-clusters-config│        │  • terraform init & apply  │
                                                        │  • gke-fleet-rbac-security  │        │  • 17 GKE Fleet Clusters   │
                                                        └─────────────────────────────┘        └────────────────────────────┘
```

---

## 🛠️ Step 1: Sync `org-mono-repo` to Destination Repository (`gke-fleet-iac`)

You can run the automated script [`scripts/sync_repo_to_destination.sh`](file:///usr/local/google/home/fcurrie/Projects/org-mono-repo/scripts/sync_repo_to_destination.sh) or execute the steps manually:

```bash
# Automated 1-Command Mirroring & Stale PR/Issue Cleanup
./scripts/sync_repo_to_destination.sh fkc1e100 gke-fleet-iac
```

### Manual Execution Steps:

#### 1.1 Close Stale PRs and Issues on Destination Repository
```bash
export GITHUB_ORG="fkc1e100"
export TARGET_REPO="gke-fleet-iac"

# Close all open Pull Requests
for pr in $(gh pr list --repo "${GITHUB_ORG}/${TARGET_REPO}" --json number --jq '.[].number'); do
  gh pr close "$pr" --repo "${GITHUB_ORG}/${TARGET_REPO}" --comment "Closing as part of complete fleet sync."
done

# Close all open Issues
for issue in $(gh issue list --repo "${GITHUB_ORG}/${TARGET_REPO}" --json number --jq '.[].number'); do
  gh issue close "$issue" --repo "${GITHUB_ORG}/${TARGET_REPO}" --comment "Closing stale issue as repo content is reset."
done
```

#### 1.2 Mirror & Overwrite Repository Contents
```bash
# Clone source (Read-Only) and target repositories
git clone https://github.com/fkc1e100/org-mono-repo.git /tmp/src-repo
git clone https://github.com/fkc1e100/gke-fleet-iac.git /tmp/dst-repo

# Completely overwrite target directory (excluding .git)
rsync -av --delete --exclude='.git' /tmp/src-repo/ /tmp/dst-repo/

# Commit and force push to main
cd /tmp/dst-repo
git add -A
git commit -m "feat: complete sync and overwrite from org-mono-repo"
git push origin main --force
```

---

## 🐙 Step 2: Configure Argo CD GitOps Monitoring (No KCC)

### 2.1 Register Repository in Argo CD
```bash
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: repo-gke-fleet-iac
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/fkc1e100/gke-fleet-iac.git
  name: gke-fleet-iac
EOF
```

### 2.2 Apply Argo CD Application Suite (`gce/argocd-fleet-apps.yaml`)
Apply the Application Suite manifest to monitor microservices, cluster configurations, and RBAC policies:

```bash
kubectl apply -f gce/argocd-fleet-apps.yaml -n argocd
```

---

## 🏗️ Step 3: Setup Keyless GitHub Actions CI/CD for Terraform

### 3.1 Provision GCP Service Account & Workload Identity Federation
```bash
export PROJECT_ID="gca-gke-2025"
export SA_NAME="github-actions-tf-sa"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
export GITHUB_ORG="fkc1e100"

# 1. Create dedicated Service Account
gcloud iam service-accounts create "${SA_NAME}" \
  --display-name="GitHub Actions Terraform Runner SA" \
  --project="${PROJECT_ID}"

# 2. Grant Admin / Editor permissions
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/editor" --condition=None

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.admin" --condition=None

# 3. Bind Workload Identity User role to GitHub Actions OIDC Issuer
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/764460891170/locations/global/workloadIdentityPools/github-actions/attribute.repository_owner/${GITHUB_ORG}" \
  --project="${PROJECT_ID}"
```

### 3.2 Verify Workflow File (`.github/workflows/terraform-apply.yaml`)
The workflow is saved at `.github/workflows/terraform-apply.yaml` and supports `workflow_dispatch`, `pull_request`, and `push` triggers.

### 3.3 Trigger Automated Provisioning
```bash
git add .github/workflows/terraform-apply.yaml
git commit -m "ci(github): add workflow_dispatch trigger to Terraform CI/CD pipeline"
git push origin main

# Trigger workflow execution via GitHub CLI
gh workflow run terraform-apply.yaml --repo fkc1e100/gke-fleet-iac
```
