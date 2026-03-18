#!/usr/bin/env bash
# generate-kubeconfig.sh — Generate a scoped kubeconfig for GitHub Actions CI service account
#
# Usage: ./scripts/generate-kubeconfig.sh <namespace>
#   namespace: production | staging
#
# Output: base64-encoded kubeconfig to stdout (paste directly into GitHub Secret)
#
# Full tutorial: https://iamdevbox.com/posts/setting-up-a-cicd-pipeline-to-kubernetes-with-github-actions/

set -euo pipefail

NAMESPACE="${1:-production}"
SA_NAME="github-actions"

echo "Generating kubeconfig for ServiceAccount '${SA_NAME}' in namespace '${NAMESPACE}'..." >&2

# Verify the service account exists
if ! kubectl get serviceaccount "${SA_NAME}" -n "${NAMESPACE}" &>/dev/null; then
  echo "ERROR: ServiceAccount '${SA_NAME}' not found in namespace '${NAMESPACE}'" >&2
  echo "Run: kubectl apply -f k8s/rbac.yaml" >&2
  exit 1
fi

# Create a bound service account token (valid for 1 year)
SA_TOKEN=$(kubectl create token "${SA_NAME}" \
  -n "${NAMESPACE}" \
  --duration=8760h)

# Get cluster CA certificate
CA_CERT=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

# Get API server URL
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')

# Build minimal kubeconfig
KUBECONFIG_CONTENT=$(cat <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CA_CERT}
    server: ${API_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: ${NAMESPACE}
    user: ${SA_NAME}
  name: github-actions-context
current-context: github-actions-context
users:
- name: ${SA_NAME}
  user:
    token: ${SA_TOKEN}
EOF
)

# Output base64 for direct paste into GitHub Secret
echo "" >&2
echo "✅ Kubeconfig generated. Copy the output below and paste it into:" >&2
echo "   GitHub repo → Settings → Secrets → Actions → KUBE_CONFIG_$(echo ${NAMESPACE} | tr '[:lower:]' '[:upper:]')" >&2
echo "" >&2

echo "${KUBECONFIG_CONTENT}" | base64 | tr -d '\n'
echo ""
