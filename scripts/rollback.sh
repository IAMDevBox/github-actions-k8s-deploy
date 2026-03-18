#!/usr/bin/env bash
# rollback.sh — Emergency rollback for blue-green deployments
#
# Usage: ./scripts/rollback.sh [namespace]
#   namespace: production (default)
#
# Full tutorial: https://iamdevbox.com/posts/setting-up-a-cicd-pipeline-to-kubernetes-with-github-actions/

set -euo pipefail

NAMESPACE="${1:-production}"

echo "🚨 Emergency rollback in namespace: ${NAMESPACE}"
echo "Switching service selector back to 'blue'..."

kubectl patch service myapp -n "${NAMESPACE}" \
  -p '{"spec":{"selector":{"version":"blue"}}}'

echo "✅ Traffic restored to blue deployment."
echo ""
echo "Current service selector:"
kubectl get service myapp -n "${NAMESPACE}" -o jsonpath='{.spec.selector}' | python3 -m json.tool
echo ""

echo "Pod status:"
kubectl get pods -n "${NAMESPACE}" -l app=myapp --show-labels
