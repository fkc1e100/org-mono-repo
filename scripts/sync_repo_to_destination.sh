#!/usr/bin/env bash
set -eo pipefail

echo "============================================================"
echo " Enterprise Monorepo Mirror & Synchronization Tool"
echo "============================================================"

# Interactive resolution for target organization and repository
TARGET_ORG="${GITHUB_ORG:-${1}}"
TARGET_REPO="${TARGET_REPO:-${2}}"

if [ -z "${TARGET_ORG}" ] && [ -t 0 ]; then
  read -p "Enter Target GitHub Organization/User (e.g. fkc1e100): " TARGET_ORG
fi

if [ -z "${TARGET_REPO}" ] && [ -t 0 ]; then
  read -p "Enter Target Destination Repository Name (e.g. gke-fleet-iac): " TARGET_REPO
fi

TARGET_ORG="${TARGET_ORG:-fkc1e100}"
TARGET_REPO="${TARGET_REPO:-gke-fleet-iac}"

echo "Source Repository: fkc1e100/org-mono-repo"
echo "Target Destination: ${TARGET_ORG}/${TARGET_REPO}"

# 1. Close Stale PRs and Issues on Destination Repository
if command -v gh >/dev/null 2>&1; then
  echo "=== Closing Stale Pull Requests and Issues on ${TARGET_ORG}/${TARGET_REPO} ==="
  for pr in $(gh pr list --repo "${TARGET_ORG}/${TARGET_REPO}" --json number --jq '.[].number' 2>/dev/null || true); do
    echo "Closing PR #${pr}..."
    gh pr close "$pr" --repo "${TARGET_ORG}/${TARGET_REPO}" --comment "Closing as part of complete fleet sync from org-mono-repo." || true
  done

  for issue in $(gh issue list --repo "${TARGET_ORG}/${TARGET_REPO}" --json number --jq '.[].number' 2>/dev/null || true); do
    echo "Closing Issue #${issue}..."
    gh issue close "$issue" --repo "${TARGET_ORG}/${TARGET_REPO}" --comment "Closing stale issue as repo content is reset." || true
  done
fi

# 2. Mirror & Overwrite Repository Contents
TMP_SRC="/tmp/src-org-mono-repo-$$"
TMP_DST="/tmp/dst-${TARGET_REPO}-$$"

trap 'rm -rf "${TMP_SRC}" "${TMP_DST}"' EXIT

echo "=== Cloning source and target repositories ==="
git clone https://github.com/fkc1e100/org-mono-repo.git "${TMP_SRC}"
git clone "https://github.com/${TARGET_ORG}/${TARGET_REPO}.git" "${TMP_DST}"

echo "=== Overwriting target repository contents ==="
rsync -av --delete --exclude='.git' "${TMP_SRC}/" "${TMP_DST}/"

cd "${TMP_DST}"
git add -A
if git diff-index --quiet HEAD --; then
  echo "✔ Target repository is already up-to-date with org-mono-repo."
else
  git commit -m "feat: complete sync and overwrite from org-mono-repo"
  echo "=== Force pushing updated main branch ==="
  git push origin main --force
  echo "✔ Successfully synced org-mono-repo to ${TARGET_ORG}/${TARGET_REPO}"
fi
