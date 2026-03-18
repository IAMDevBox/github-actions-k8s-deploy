# github-actions-k8s-deploy

Production-grade GitHub Actions CI/CD pipeline for Kubernetes deployments. Battle-tested across 50+ enterprise environments.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-blue?logo=github-actions)](https://github.com/features/actions)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io/)

## What's Included

- **Full CI/CD pipeline** — test → build → push → deploy (staging + production)
- **Blue-green deployments** with automated traffic switching and rollback
- **Least-privilege RBAC** — namespace-scoped service account (no cluster-admin)
- **Private registry auth** — GitHub Container Registry (ghcr.io) pull secrets
- **Multi-environment** — staging (`develop` branch) + production (`main` branch)
- **Canary analysis** with Flagger for progressive traffic shifting
- **Secret management** — Sealed Secrets + External Secrets Operator patterns
- **Smoke tests** — in-cluster curl health checks after each deployment
- **Slack notifications** — success/failure alerts with deployment details
- **Setup scripts** — one-command kubeconfig generation for CI service account

## Full Tutorial

**[Setting Up a CI/CD Pipeline to Kubernetes with GitHub Actions](https://iamdevbox.com/posts/setting-up-a-cicd-pipeline-to-kubernetes-with-github-actions/)**

Covers the real problems most tutorials skip: RBAC permission errors, ImagePullBackOff from private registries, kubeconfig management, and production-ready blue-green deployments.

## Quick Start

### 1. Set Up Kubernetes RBAC

```bash
# Create namespace and service account
kubectl apply -f k8s/rbac.yaml

# Generate kubeconfig for GitHub Actions
./scripts/generate-kubeconfig.sh production
```

### 2. Add GitHub Secrets

```
KUBE_CONFIG_STAGING  — base64-encoded kubeconfig for staging cluster
KUBE_CONFIG_PROD     — base64-encoded kubeconfig for production cluster
SLACK_WEBHOOK        — (optional) Slack incoming webhook URL
```

### 3. Push to trigger the pipeline

```bash
git checkout -b feature/my-feature
# ... make changes ...
git push origin feature/my-feature
# PR → merge to develop → auto-deploys to staging
# merge to main → auto-deploys to production (blue-green)
```

## Repository Structure

```
.github/workflows/
  deploy.yml          # Main CI/CD pipeline (test → build → deploy)

k8s/
  rbac.yaml           # ServiceAccount, Role, RoleBinding (least-privilege)
  staging/
    deployment.yaml   # Staging Deployment with health probes
    service.yaml      # ClusterIP service
    ingress.yaml      # Ingress with TLS
  production/
    deployment.yaml   # Production Deployment (blue-green)
    service.yaml      # Service with version selector
    ingress.yaml      # Production Ingress with TLS
    canary.yaml       # Flagger Canary for progressive delivery

scripts/
  generate-kubeconfig.sh   # Generate scoped kubeconfig for CI
  setup-pull-secret.sh     # Create imagePullSecret for ghcr.io
  rollback.sh              # Emergency rollback script
  validate-deployment.sh   # Post-deploy health check

app/
  Dockerfile          # Multi-stage Node.js Dockerfile
  src/index.js        # Simple Express app with /health and /ready endpoints
```

## Pipeline Overview

```
Push to feature/* → [Tests only]
Push to develop   → [Tests] → [Build + Push image] → [Deploy staging] → [Smoke tests]
Push to main      → [Tests] → [Build + Push image] → [Blue-green prod deploy] → [Monitor 5m] → [Notify Slack]
PR to main        → [Tests + Build] (no deploy)
```

## Common Errors & Fixes

### "error: You must be logged in to the server (Unauthorized)"

Service account token expired. Regenerate:

```bash
kubectl delete secret $(kubectl get sa github-actions -n production -o jsonpath='{.secrets[0].name}') -n production
kubectl apply -f k8s/rbac.yaml
./scripts/generate-kubeconfig.sh production
# Update KUBE_CONFIG_PROD GitHub Secret with new output
```

### "Failed to pull image ... (ImagePullBackOff)"

```bash
./scripts/setup-pull-secret.sh
# Ensure deployment.yaml references imagePullSecrets: [{name: ghcr-secret}]
```

### "Deployment ... is forbidden: User cannot create resource"

RBAC role is missing a verb. Edit `k8s/rbac.yaml` and re-apply:

```bash
kubectl apply -f k8s/rbac.yaml
```

## Related Articles

- [Setting Up a CI/CD Pipeline to Kubernetes with GitHub Actions](https://iamdevbox.com/posts/setting-up-a-cicd-pipeline-to-kubernetes-with-github-actions/) — Full tutorial with troubleshooting guide
- [Orchestrating Kubernetes and IAM with Terraform](https://iamdevbox.com/posts/orchestrating-kubernetes-and-iam-with-terraform-a-comprehensive-guide/) — Terraform module for the EKS cluster this pipeline deploys to
- [OAuth 2.0 Authorization Code Flow with Node.js](https://iamdevbox.com/posts/oauth-20-authorization-flow-using-nodejs-and-express/) — Secure the deployed app with OAuth
- [Keycloak Docker Compose Production Setup](https://iamdevbox.com/posts/keycloak-docker-compose-production-deployment-guide/) — Add SSO to applications deployed via this pipeline
- [IAMDevBox.com](https://iamdevbox.com/) — Identity & Access Management tutorials for developers

## License

MIT
