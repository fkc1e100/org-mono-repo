#!/usr/bin/env bash
set -eo pipefail

echo "============================================================"
echo " Setting Up ArgoCD GitOps Continuous Reconciliation"
echo "============================================================"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# -------------------------------------------------------------------
# 1. Detect Git Remote URL (Fork Resolution)
# -------------------------------------------------------------------
GIT_REPO_URL="$(git config --get remote.origin.url || echo "https://github.com/fkc1e100/org-mono-repo.git")"

# Convert SSH git URL format to HTTPS if necessary
if [[ "$GIT_REPO_URL" =~ ^git@github\.com:(.+)\.git$ ]]; then
  GIT_REPO_URL="https://github.com/${BASH_REMATCH[1]}.git"
fi

echo "Detected GitOps Repository URL: ${GIT_REPO_URL}"

# -------------------------------------------------------------------
# 2. Check if ArgoCD is Already Installed
# -------------------------------------------------------------------
if kubectl get ns argocd >/dev/null 2>&1; then
  echo "✔ ArgoCD namespace 'argocd' already exists."
else
  echo "➜ ArgoCD not found. Installing official ArgoCD core manifests..."
  kubectl create namespace argocd
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  
  echo "Waiting for ArgoCD server rollout..."
  kubectl rollout status deployment/argocd-server -n argocd --timeout=180s || true
fi

# -------------------------------------------------------------------
# 3. Configure gce/argocd-app.yaml with Detected Repo URL
# -------------------------------------------------------------------
echo "Configuring gce/argocd-app.yaml with repository URL: ${GIT_REPO_URL}"
sed -i "s|repoURL: '.*'|repoURL: '${GIT_REPO_URL}'|g" "${REPO_ROOT}/gce/argocd-app.yaml"

# -------------------------------------------------------------------
# 4. Apply ArgoCD Application
# -------------------------------------------------------------------
echo "Applying ArgoCD Application 'gce-infrastructure-fleet'..."
kubectl apply -f "${REPO_ROOT}/gce/argocd-app.yaml" -n argocd

echo "============================================================"
echo " ✔ ArgoCD GitOps Setup Complete!"
echo "============================================================"
echo " To access ArgoCD Web UI:"
echo "   1. Fetch initial admin password:"
echo "      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d; echo"
echo "   2. Port forward ArgoCD server:"
echo "      kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   3. Open https://localhost:8080 (User: admin)"
echo "============================================================"
