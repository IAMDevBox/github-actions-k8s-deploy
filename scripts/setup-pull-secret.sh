#!/usr/bin/env bash
# setup-pull-secret.sh — Create imagePullSecret for GitHub Container Registry (ghcr.io)
#
# Usage: ./scripts/setup-pull-secret.sh
#
# Requires: GITHUB_USERNAME and GITHUB_TOKEN env vars (token needs read:packages scope)
#
# Full tutorial: https://iamdevbox.com/posts/setting-up-a-cicd-pipeline-to-kubernetes-with-github-actions/

set -euo pipefail

GITHUB_USERNAME="${GITHUB_USERNAME:?Set GITHUB_USERNAME environment variable}"
GITHUB_TOKEN="${GITHUB_TOKEN:?Set GITHUB_TOKEN environment variable (needs read:packages scope)}"

for NAMESPACE in production staging; do
  echo "Creating ghcr.io pull secret in namespace: ${NAMESPACE}"

  kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username="${GITHUB_USERNAME}" \
    --docker-password="${GITHUB_TOKEN}" \
    --namespace="${NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f -

  echo "  ✅ ghcr-secret created/updated in ${NAMESPACE}"
done

echo ""
echo "Done. Deployments with 'imagePullSecrets: [{name: ghcr-secret}]' can now pull from ghcr.io."
