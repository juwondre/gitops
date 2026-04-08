# GitOps - Enterprise CI/CD with CircleCI

[![CircleCI](https://circleci.com/gh/juwondre/gitops.svg?style=shield)](https://circleci.com/gh/juwondre/gitops)

Enterprise CI/CD pipeline for NGINX on Kubernetes, powered by CircleCI with GitFlow branching, multi-layer security scanning, and ArgoCD-based GitOps deployment.

## Architecture

```
Developer Push
       │
       ▼
┌─────────────┐   ┌──────────────────────────────────────────┐
│  Git Repo   │──▶│  CircleCI Pipeline                       │
│             │   │                                          │
│  feature/*  │   │  validate ─▶ build ─▶ scan ─▶ push      │
│  develop    │   │    │ hadolint    │ DLC    │ trivy   │    │
│  release/*  │   │    │ kubeconform │        │ snyk    │    │
│  main       │   │    │ helm lint   │        │         │    │
│  hotfix/*   │   │    │ yamllint    │        │         │    │
└─────────────┘   └──────────────────────────────┬───────────┘
                                                 │
                                          update manifests
                                          (image tag bump)
                                                 │
                                                 ▼
                                          ┌─────────────┐
                                          │  ArgoCD     │──▶ K8s Cluster
                                          │  (sync)     │
                                          └─────────────┘
```

## Branching Strategy (GitFlow)

| Branch | Purpose | Pipeline Stages |
|--------|---------|-----------------|
| `feature/*` | Development work | validate |
| `develop` | Integration | validate → build → scan → push → update manifests |
| `release/*` | Release candidates | validate → build → scan → push → update manifests |
| `hotfix/*` | Emergency fixes | validate → build → scan → push → update manifests |
| `main` | Production | validate → build → scan → push → **manual approval** → update manifests |

## Security Scanning

| Layer | Tool | Scope |
|-------|------|-------|
| Dockerfile | [Hadolint](https://github.com/hadolint/hadolint) | Best-practice linting |
| Container image | [Trivy](https://github.com/aquasecurity/trivy) | CVE scanning (CRITICAL blocks pipeline) |
| Container image | [Snyk](https://snyk.io/) | Vulnerability + license analysis |
| K8s manifests | [Kubeconform](https://github.com/yannh/kubeconform) | Schema validation |
| K8s manifests | Trivy config scan | Misconfiguration detection |
| K8s manifests | Snyk IaC | Infrastructure-as-code policy |
| Secrets | CircleCI Contexts | Scoped per environment, never in code |

## Image Tagging Strategy

| Branch | Tag Format | Example |
|--------|-----------|---------|
| `develop` | `develop-<sha>` | `develop-a1b2c3d` |
| `release/*` | `rc-<version>-<sha>` | `rc-1.2.0-a1b2c3d` |
| `hotfix/*` | `hotfix-<sha>` | `hotfix-a1b2c3d` |
| `main` | `latest` + `v1.0.0-<sha>` | `latest`, `v1.0.0-a1b2c3d` |

## Setup

### Prerequisites

1. [CircleCI account](https://circleci.com/) connected to your GitHub
2. [Docker Hub account](https://hub.docker.com/) for image registry
3. [Snyk account](https://snyk.io/) (free tier) for vulnerability scanning

### CircleCI Configuration

1. **Connect repo**: CircleCI → Projects → Set Up Project → select `juwondre/gitops`
2. **Create contexts** (Organization Settings → Contexts):

   **`docker-credentials`**:
   - `DOCKERHUB_USERNAME` - your Docker Hub username
   - `DOCKERHUB_PASSWORD` - Docker Hub access token

   **`snyk-credentials`**:
   - `SNYK_TOKEN` - Snyk API token

3. **Push to a branch** and the pipeline will run automatically

### Local Development

```bash
# Build image locally
docker build -t gitops-nginx:local .

# Run locally
docker run -p 8080:8080 gitops-nginx:local

# Health check
curl http://localhost:8080/healthz
```

## Project Structure

```
.
├── .circleci/
│   └── config.yml          # CircleCI pipeline definition
├── charts/
│   └── helm/
│       └── deployment.yaml # Helm-based K8s deployment
├── nginx/
│   └── default.conf        # Custom NGINX configuration
├── nginx-deployment/
│   └── nginx.yaml          # Raw K8s deployment manifest
├── .dockerignore            # Docker build exclusions
├── .snyk                    # Snyk policy file
├── .trivyignore             # Trivy CVE suppressions
├── Dockerfile               # Multi-stage NGINX image
└── README.md
```
