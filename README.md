# DevOps Journey

A hands-on, incremental build-up of core DevOps skills — containerization, orchestration, infrastructure as code, and templated deployments — using one real application as the through-line rather than disconnected tutorials.

Each stage in this repo was built, broken, debugged, and pushed as a real commit — the history reflects actual problem-solving (YAML indentation errors, GitHub token scopes, IAM permissions, DNS misconfiguration, cross-cluster Secrets), not a single copy-paste dump.

## Architecture

```
 Local Node.js app (myapp/app.js)
          │
          ▼
   Dockerfile → Docker image
          │
          ├────────────────────────────┐
          ▼                            ▼
  Local Kubernetes                 Pushed to AWS ECR
  (Docker Desktop)                        │
          │                              ▼
          │                     Terraform provisions:
          │                     ┌──────────────────────────┐
          │                     │  VPC (reused, existing)  │
          │                     │  EKS cluster (control    │
          │                     │    plane, managed by AWS)│
          │                     │  Node Group (2 EC2       │
          │                     │    worker nodes, 2 AZs)  │
          │                     │  IAM roles for cluster   │
          │                     │    + nodes               │
          │                     └──────────────────────────┘
          │                              │
          ▼                              ▼
   ┌─────────────────────────────────────────────┐
   │        Helm chart (helm/myapp)              │
   │   templates/deployment.yaml, service.yaml   │
   │   values.yaml (defaults) + values-aws.yaml  │
   │   (environment-specific overrides)          │
   └─────────────────────────────────────────────┘
          │                              │
          ▼                              ▼
  Deployment → 3 Pods            Deployment → 3 Pods
  Service (LoadBalancer)         Service (real AWS ELB)
  → localhost:8080               → public *.elb.amazonaws.com

   GitHub Actions CI
     → checks out code, builds Docker image
       on every push to main
```

## What's implemented so far

**Containerization**
- Node.js HTTP server — a minimal app, deliberately simple so the DevOps tooling around it stays the focus
- Docker — the app is containerized via a `Dockerfile`; image builds locally and runs identically regardless of host setup

**Kubernetes (local cluster via Docker Desktop)**
- `Deployment` running 3 replicas, self-healing verified (manually killed a pod, confirmed automatic replacement)
- `Service` (`LoadBalancer`) exposing the app externally at `localhost:8080`, plus a second `ClusterIP` service used to demonstrate internal-only accessibility
- `ConfigMap` externalizing app configuration (`APP_MESSAGE`) — read via an environment variable, so the message can change without rebuilding the Docker image
- `Secret` for sensitive configuration (`API_KEY`), created directly via `kubectl` and never committed in plaintext

**CI (GitHub Actions)**
- Every push to `main` automatically checks out the repo and builds the Docker image, catching build-breaking errors before they'd reach a real deployment

**Infrastructure as Code (Terraform)**
- Reuses an existing VPC/subnet from a separate AWS repo via `data` sources, demonstrating cross-project infrastructure references
- Provisions a Security Group, SSH key pair, and EC2 instance (early exercise — since torn down)
- Provisions an ECR repository to store the Docker image for cloud use
- Provisions a full EKS cluster: control plane, a Node Group (2 worker EC2 instances across 2 Availability Zones), and the IAM roles/policies both require

**Cloud deployment (AWS EKS)**
- Same Kubernetes manifests as the local setup, pointed at the ECR-hosted image, deployed to a real AWS-managed Kubernetes cluster
- Verified end-to-end: `kubectl get nodes` (real EC2 workers), `kubectl get pods` (app running), and the app reachable via a real AWS Load Balancer's public DNS address

**Helm**
- Converted the Kubernetes manifests into a templated Helm chart (`helm/myapp`)
- One chart, two environments: `values.yaml` (local defaults) and `values-aws.yaml` (AWS-specific overrides — ECR image, updated message) — no duplicated YAML between environments
- Deployed as a Helm release locally (`myapp-local`), verified against the same behavior as the manual `kubectl apply` version

**Bash scripting**
- A small automation script for timestamped file backups

## Repository structure

```
.
├── .github/workflows/
│   └── docker-build.yml       # CI: builds the Docker image on every push
├── myapp/
│   ├── app.js                  # Node.js HTTP server
│   ├── Dockerfile
│   └── README.md
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── service-internal.yaml
│   └── configmap.yaml
├── helm/
│   └── myapp/
│       ├── Chart.yaml
│       ├── values.yaml         # local defaults
│       ├── values-aws.yaml     # AWS-specific overrides
│       └── templates/
│           ├── deployment.yaml
│           └── service.yaml
├── terraform/
│   ├── main.tf                 # VPC/subnet reuse (data sources), routing
│   ├── ecr.tf                  # ECR repository
│   ├── eks.tf                  # EKS cluster, node group, IAM roles
│   └── .gitignore               # excludes state files, local plugin cache
└── README.md                    # you are here
```

## Running it locally

**Directly with Docker:**
```bash
cd myapp
docker build -t myapp .
docker run -p 8000:8000 myapp
```

**On local Kubernetes (Docker Desktop → enable Kubernetes):**
```bash
cd k8s
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods
# then open http://localhost:8080
```

**Or via Helm (recommended — same chart works for local or AWS):**
```bash
cd helm
helm install myapp-local ./myapp
kubectl get pods
```

## Deploying to AWS

```bash
# 1. Provision infrastructure
cd terraform
terraform apply

# 2. Push the image to ECR (see terraform output for the registry URL)
cd ../myapp
docker build -t myapp .
docker tag myapp:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/devops-journey-myapp:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/devops-journey-myapp:latest

# 3. Point kubectl at the new cluster
aws eks update-kubeconfig --region us-east-1 --name devops-journey-cluster

# 4. Recreate the Secret (Secrets don't persist across clusters)
kubectl create secret generic myapp-secret --from-literal=API_KEY=demo-key-12345

# 5. Deploy via Helm, using the AWS-specific values
cd ../helm
helm install myapp-aws ./myapp -f ./myapp/values-aws.yaml
kubectl get services   # grab the LoadBalancer's public DNS name

# 6. Tear down when done, to avoid ongoing cost
kubectl delete service myapp-service
cd ../terraform
terraform destroy
```

## Notes from building this

- Kubernetes and Terraform files are sensitive to exact indentation — spaces only, never tabs.
- A GitHub Actions workflow only runs if it lives at the repo root under `.github/workflows/` — an early version was nested inside a subfolder and silently never triggered.
- Personal Access Tokens need the `workflow` scope specifically to push changes to `.github/workflows/` files.
- AWS Free Tier EC2 eligibility depends on the account — check with `aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true"` rather than assuming `t2.micro`.
- EKS requires subnets across at least two Availability Zones for the control plane.
- Worker nodes failed to join the cluster the first time, due to `enableDnsHostnames` being disabled on the (pre-existing, reused) VPC — fixed via `aws ec2 modify-vpc-attribute`.
- A second subnet added for the extra Availability Zone needs its own explicit route table association, or its nodes have no path to the internet and silently fail to register.
- Kubernetes Secrets created via `kubectl create secret` (rather than from a file) don't carry over between clusters — they must be recreated on each new cluster.
- Helm refuses to manage resources it didn't originally create — pre-existing `kubectl apply`-created resources need to be deleted before a matching Helm release can be installed.
- `terraform destroy` can fail if an ECR repository still holds an image (`force_delete = true` resolves this) or if a Kubernetes-created Load Balancer is deleted after — not before — the underlying VPC/subnets.

## Roadmap

- [x] Kubernetes `Secret` for sensitive configuration
- [x] Helm chart to manage this as a reusable, versioned deployment
- [x] Terraform (IaC) to provision real cloud infrastructure on AWS
- [x] Deploy this stack to a real AWS Kubernetes cluster (EKS)
- [ ] Extend CI into full CD — automatic build, push to ECR, and deploy to EKS on push
- [ ] Monitoring with Prometheus + Grafana