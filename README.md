# DevOps Journey

A hands-on, incremental build-up of core DevOps skills — containerization, orchestration, and automated pipelines — using one real application as the through-line rather than disconnected tutorials.

Each stage in this repo was built, broken, debugged, and pushed as a real commit — the history reflects actual problem-solving (YAML indentation errors, GitHub token scopes, working-directory issues), not a single copy-paste dump.

## Architecture

```
 Local Node.js app (myapp/app.js)
          │
          ▼
   Dockerfile → Docker image (myapp:latest)
          │
          ▼
 ┌────────────────────────────────────────--┐
 │         Kubernetes (local cluster)       │
 │                                          │
 │   Deployment (myapp-deployment)          │
 │     → ReplicaSet → 3 Pods                │
 │                                          │
 │   ConfigMap (myapp-config)               │
 │     → injects APP_MESSAGE into pods      │
 │                                          │
 │   Service (myapp-service, LoadBalancer)  │
 │     → stable entrypoint → localhost:8080 │
 └────────────────────────────────────────--┘
          │
          ▼
   GitHub Actions CI
     → checks out code, builds Docker image
       on every push to main
```

## What's implemented so far

- **Node.js HTTP server** — a minimal app, deliberately simple so the DevOps tooling around it stays the focus
- **Docker** — the app is containerized via a `Dockerfile`; image builds locally and runs identically regardless of host setup
- **Kubernetes (local cluster via Docker Desktop)**
  - `Deployment` running 3 replicas, self-healing verified (manually killed a pod, confirmed automatic replacement)
  - `Service` (`LoadBalancer`) exposing the app externally at `localhost:8080`
  - A second `ClusterIP` service used to demonstrate internal-only accessibility
  - `ConfigMap` externalizing app configuration (`APP_MESSAGE`) — the app reads it via an environment variable, so the message can change without rebuilding the Docker image
- **CI (GitHub Actions)** — every push to `main` automatically checks out the repo and builds the Docker image, catching build-breaking errors before they'd reach a real deployment
- **Bash scripting** — a small automation script for timestamped file backups

## Repository structure

```
.
├── .github/workflows/
│   └── docker-build.yml     # CI: builds the Docker image on every push
├── myapp/
│   ├── app.js                # Node.js HTTP server
│   ├── Dockerfile
│   └── README.md
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── service-internal.yaml
│   └── configmap.yaml
└── README.md                 # you are here
```

## Running it locally

```bash
# Build and run with Docker directly
cd myapp
docker build -t myapp .
docker run -p 8000:8000 myapp

# Or deploy to a local Kubernetes cluster (Docker Desktop → enable Kubernetes)
cd k8s
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods
# then open http://localhost:8080
```

## Notes from building this

- Kubernetes manifests (`.github/workflows/`, `k8s/*.yaml`) are sensitive to exact indentation — spaces only, never tabs. A couple of early commits show this being debugged directly.
- A GitHub Actions workflow only runs if it lives at the **repo root** under `.github/workflows/` — an early version was nested inside a subfolder and silently never triggered.
- Personal Access Tokens need the `workflow` scope specifically to push changes to `.github/workflows/` files — a separate permission from general repo access.

## Roadmap

- [ ] Kubernetes `Secret` for sensitive configuration
- [ ] Helm chart to manage this as a reusable, versioned deployment
- [ ] Terraform (IaC) to provision real cloud infrastructure on AWS
- [ ] Deploy this stack to a real AWS Kubernetes cluster (EKS)
- [ ] Extend CI into full CD — automatic deployment to the cloud cluster on push
- [ ] Monitoring with Prometheus + Grafana