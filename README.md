# Runic Infrastructure

A modern infrastructure and application platform built with Terraform, Kubernetes, and Helm. 
Nexus is in an active development stage, with gradual improvements underway.

## Overview

This repository contains:

- **Terraform configurations** for AWS infrastructure (VPC, EKS, RDS, etc.)
- **Kubernetes manifests** for application deployments
- **Helm charts** for package management
- **Scripts** for automation and deployment
- **Docker configurations** for local development

## Projects

### Nexus (Coordination Service)

A stateful, distributed coordination service running on Kubernetes with:

- High availability (3+ replicas with consensus)
- Persistent storage (StatefulSets with PVCs)
- PostgreSQL database backend (RDS Multi-AZ)
- Secure key management (AWS KMS)
- Comprehensive monitoring (Prometheus + Grafana)

**Use Cases:**

- Distributed state coordination
- Blockchain state management
- Multi-party coordination protocols
- High-availability transaction processing

> **Note**: This project is purely for fun and experimentation—exploring how to scale Kubernetes to support low-latency stateful applications with production-grade infrastructure patterns.

**Documentation:**

- [Architecture](docs/nexus-architecture.md)
- [Deployment Guide](docs/nexus-deployment-guide.md)
- [Quick Reference](docs/nexus-quick-reference.md)

**Quick Start:**

```bash
# Clone the repository
git clone https://github.com/shanjing/runic.git
cd runic

# Option 1: Automated deployment (Terraform + Helm)
./scripts/deploy-nexus.sh

# Option 2: Manual Helm installation (requires infrastructure already deployed)
helm install nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --create-namespace

# Cleanup
./scripts/destroy-nexus.sh
```

### Trevoux (AI Travel Guide)

Trevoux is a lightweight AI/LLM-based French travel companion that surfaces curated itineraries, café finds, and cultural notes directly from Kubernetes workloads. It serves as a sandbox for experimenting with prompt-tuned inference services and low-latency API delivery on EKS.
It reuses the platform primitives in this repo to prototype inference backends alongside traditional microservices.

## GitHub Actions

- `.github/workflows/eks-helm-deploy.yml` packages the Helm charts and deploys them to EKS on each verified push.
- The workflow runs `helm lint`, renders manifests, and performs a `helm upgrade --install` as part of CI/CD.

## Observability

- `kubernetes/manifests/stratus/simple-app-podmonitor.yaml` registers the Stratus sample service with Prometheus via PodMonitor so metrics flow into the shared stack without ClusterRoles or ServiceMonitors.

## Directory Structure

```
Runic/
├── .github/                # GitHub workflows
│   └── workflows/          # CI/CD (EKS Helm deploy pipeline)
├── aws/                    # AWS utility scripts
├── docker/                 # Docker configurations
│   └── kafka/             # Local Kafka setup
├── docs/                   # Documentation
├── kubernetes/            # Kubernetes resources
│   ├── configs/           # Configuration files
│   ├── helm/              # Helm charts
│   │   └── charts/
│   │       └── nexus/     # Nexus Helm chart
│   ├── manifests/         # Raw Kubernetes manifests
│   │   ├── nexus/         # Nexus manifests
│   │   └── stratus/       # Stratus lab (Prometheus PodMonitor)
│   └── scripts/           # Kubernetes utility scripts
├── scripts/               # Automation scripts
│   ├── deploy-nexus.sh    # Deploy Nexus infrastructure
│   └── destroy-nexus.sh   # Cleanup Nexus infrastructure
└── terraform/             # Terraform configurations
    ├── envs/              # Environment-specific configs
    │   ├── dev/           # Development environment
    │   ├── nexus/         # Nexus environment
    │   ├── trevoux/       # Trevoux AI-based French traveling guide infra
    │   └── notifications/ # Billing alert SNS budget
    └── modules/           # Reusable Terraform modules
        ├── ec2/           # EC2 instances
        ├── eks/           # EKS cluster
        ├── iam/           # roles for CI/CD etc
        └── vpc/           # VPC networking
```

## Prerequisites

### Required Tools

```bash
# macOS
brew install awscli terraform kubectl helm jq

# Linux
# Install via package manager or download binaries
```

### AWS Configuration

```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

## Getting Started

### 1. Deploy Nexus Infrastructure

```bash
# Clone the repository
git clone https://github.com/shanjing/runic.git
cd runic

# Automated deployment
./scripts/deploy-nexus.sh

# Or manual step-by-step
cd terraform/envs/nexus
terraform init
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name nexus-coordination-cluster

# Deploy with Helm (can also deploy from CI/CD)
helm install nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --create-namespace
```

### 2. Verify Deployment

```bash
# Check all resources
kubectl get all -n coordination-system

# Check pod status
kubectl get pods -n coordination-system

# View logs
kubectl logs -f statefulset/nexus-cluster -n coordination-system

# Test API
kubectl port-forward svc/nexus-api 8080:8080 -n coordination-system
curl http://localhost:8080/health/ready
```

### 3. Access Services

```bash
# API endpoint (via port-forward)
kubectl port-forward svc/nexus-api 8080:8080 -n coordination-system

# Metrics endpoint
kubectl port-forward svc/nexus-api 9091:9091 -n coordination-system

# Via Ingress (if configured)
kubectl get ingress -n coordination-system
```

## Infrastructure Components

### Nexus Environment

**Compute:**

- EKS Cluster (Kubernetes 1.28)
- Managed Node Group (3-10 nodes, t3.large/xlarge)
- Auto-scaling enabled

**Storage:**

- EBS volumes (gp3) for pod storage
- RDS PostgreSQL Multi-AZ (db.t3.large)
- S3 for backups (optional)

**Networking:**

- VPC with public/private subnets across 3 AZs
- NAT Gateways for outbound traffic
- Application Load Balancer for ingress
- Network policies for pod isolation

**Security:**

- IAM Roles for Service Accounts (IRSA)
- AWS KMS for encryption
- AWS Secrets Manager for credentials
- Security groups and NACLs

**Monitoring:**

- Prometheus for metrics collection
- Grafana for visualization
- CloudWatch for AWS service logs
- Service monitors for pod metrics

## Common Operations

### Update Application

```bash
# Update Helm release (from repository root)
helm upgrade nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --set image.tag=v1.1.0

# Or update via kubectl
kubectl set image statefulset/nexus-cluster \
  nexus-node=ghcr.io/shanjing/nexus:v1.1.0 \
  -n coordination-system
```

### Scale StatefulSet

```bash
# Scale up
kubectl scale statefulset nexus-cluster --replicas=5 -n coordination-system

# Scale down
kubectl scale statefulset nexus-cluster --replicas=3 -n coordination-system
```

### View Logs

```bash
# All pods
kubectl logs -f statefulset/nexus-cluster -n coordination-system

# Specific pod
kubectl logs -f nexus-cluster-0 -n coordination-system

# Previous pod instance
kubectl logs nexus-cluster-0 -n coordination-system --previous
```

## Troubleshooting

### Common Issues

**Pods not starting:**

```bash
kubectl describe pod nexus-cluster-0 -n coordination-system
kubectl get events -n coordination-system --sort-by='.lastTimestamp'
```

**Database connection issues:**

```bash
# Check security groups
# Ensure EKS nodes can access RDS on port 5432

# Test from pod
kubectl exec -it nexus-cluster-0 -n coordination-system -- \
  psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

**Terraform state locked:**

```bash
terraform force-unlock LOCK_ID
```

**Helm release issues:**

```bash
helm list -n coordination-system
helm rollback nexus -n coordination-system
```

## Cost Management

### Estimated Monthly Costs (us-west-2)

- EKS Control Plane: ~$73
- EC2 Nodes (3x t3.large): ~$190
- RDS (db.t3.large Multi-AZ): ~$290
- NAT Gateways (3x): ~$100
- EBS Volumes: ~$20
- Data Transfer: Variable

**Total:** ~$670/month (baseline)

### Cost Optimization

**Development:**

- Use smaller instance types (t3.small/medium)
- Single-AZ RDS
- Fewer NAT gateways (1 instead of 3)
- Stop resources when not in use

**Production:**

- Use Reserved Instances or Savings Plans
- Enable auto-scaling
- Use Spot instances for non-critical workloads
- Regular resource cleanup

## Security

### Best Practices

1. **Secrets Management:** Use AWS Secrets Manager or External Secrets Operator
2. **Network Security:** Enable network policies, use private subnets
3. **Access Control:** Use IRSA, implement least privilege
4. **Encryption:** Enable encryption at rest and in transit
5. **Audit Logging:** Enable CloudWatch Logs and EKS audit logs
6. **Image Scanning:** Scan container images for vulnerabilities
7. **Regular Updates:** Keep Kubernetes, OS, and dependencies updated
