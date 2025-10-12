# Nexus Quick Reference Guide

## Quick Commands

### Deploy

```bash
./scripts/deploy-nexus.sh                    # Full automated deployment
./scripts/deploy-nexus.sh --dry-run          # Preview without deploying
./scripts/deploy-nexus.sh --skip-terraform   # Skip Terraform, deploy Helm only
```

### Destroy

```bash
./scripts/destroy-nexus.sh                   # Destroy all infrastructure
./scripts/destroy-nexus.sh --yes             # Skip confirmations
```

### Check Status

```bash
# Pods
kubectl get pods -n coordination-system -w

# All resources
kubectl get all -n coordination-system

# StatefulSet
kubectl get statefulset -n coordination-system

# Services
kubectl get svc -n coordination-system

# Ingress
kubectl get ingress -n coordination-system
```

### Logs

```bash
# Follow logs from all replicas
kubectl logs -f statefulset/nexus-cluster -n coordination-system

# Specific pod
kubectl logs -f nexus-cluster-0 -n coordination-system

# Previous instance (after restart)
kubectl logs nexus-cluster-0 -n coordination-system --previous
```

### Port Forwarding

```bash
# API endpoint
kubectl port-forward svc/nexus-api 8080:8080 -n coordination-system

# Metrics endpoint
kubectl port-forward svc/nexus-api 9091:9091 -n coordination-system
```

### Helm Operations

```bash
# Install from repository
helm install nexus ./kubernetes/helm/charts/nexus -n coordination-system --create-namespace

# List releases
helm list -n coordination-system

# Upgrade
helm upgrade nexus ./kubernetes/helm/charts/nexus -n coordination-system

# Upgrade with new values
helm upgrade nexus ./kubernetes/helm/charts/nexus -n coordination-system -f my-values.yaml

# Rollback
helm rollback nexus -n coordination-system

# Get values
helm get values nexus -n coordination-system

# Get all release info
helm get all nexus -n coordination-system

# Uninstall
helm uninstall nexus -n coordination-system
```

### Terraform Operations

```bash
cd terraform/envs/nexus

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Destroy
terraform destroy

# Show outputs
terraform output

# Refresh state
terraform refresh
```

### Database Operations

```bash
# Get RDS endpoint
terraform -chdir=terraform/envs/nexus output rds_endpoint

# Get credentials
SECRET_ARN=$(terraform -chdir=terraform/envs/nexus output -raw rds_credentials_secret_arn)
aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq .

# Connect from pod
kubectl exec -it nexus-cluster-0 -n coordination-system -- psql -h $DB_HOST -U $DB_USER -d $DB_NAME

# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier nexus-coordination-cluster-db \
  --db-snapshot-identifier nexus-snapshot-$(date +%Y%m%d)
```

### Scaling

```bash
# Scale StatefulSet
kubectl scale statefulset nexus-cluster --replicas=5 -n coordination-system

# Update resources
kubectl set resources statefulset nexus-cluster \
  --limits=cpu=4000m,memory=8Gi \
  --requests=cpu=1000m,memory=2Gi \
  -n coordination-system
```

### Troubleshooting

```bash
# Describe pod
kubectl describe pod nexus-cluster-0 -n coordination-system

# Events
kubectl get events -n coordination-system --sort-by='.lastTimestamp'

# Exec into pod
kubectl exec -it nexus-cluster-0 -n coordination-system -- sh

# Check PVC
kubectl get pvc -n coordination-system
kubectl describe pvc nexus-data-nexus-cluster-0 -n coordination-system

# Network test
kubectl exec -it nexus-cluster-0 -n coordination-system -- \
  nc -zv nexus-cluster-1.nexus-headless.coordination-system.svc.cluster.local 9090
```

## File Locations

| Component            | Location                       |
| -------------------- | ------------------------------ |
| Architecture Docs    | `docs/nexus-architecture.md`     |
| Deployment Guide     | `docs/nexus-deployment-guide.md` |
| Terraform Config     | `terraform/envs/nexus/`          |
| Kubernetes Manifests | `kubernetes/manifests/nexus/`    |
| Helm Chart           | `kubernetes/helm/charts/nexus/`  |
| Deploy Script        | `scripts/deploy-nexus.sh`        |
| Destroy Script       | `scripts/destroy-nexus.sh`       |

## Important Endpoints

| Service   | Port | Path            | Purpose             |
| --------- | ---- | --------------- | ------------------- |
| API       | 8080 | `/`             | Main API            |
| API       | 8080 | `/health/ready` | Readiness check     |
| API       | 8080 | `/health/live`  | Liveness check      |
| Consensus | 9090 | -               | Inter-pod consensus |
| Metrics   | 9091 | `/metrics`      | Prometheus metrics  |

## Default Configuration

| Setting        | Value                  |
| -------------- | ---------------------- |
| Namespace      | `coordination-system`  |
| Replicas       | 3                      |
| Storage        | 20Gi per pod (gp3)     |
| CPU Request    | 500m                   |
| Memory Request | 1Gi                    |
| CPU Limit      | 2000m                  |
| Memory Limit   | 4Gi                    |
| Database       | PostgreSQL 15.4        |
| RDS Instance   | db.t3.large (Multi-AZ) |

## URLs and Naming

| Resource          | Name/Pattern                                      |
| ----------------- | ------------------------------------------------- |
| Cluster           | `nexus-coordination-cluster`                        |
| Namespace         | `coordination-system`                             |
| StatefulSet       | `nexus-cluster`                                     |
| Pods              | `nexus-cluster-0`, `nexus-cluster-1`, `nexus-cluster-2` |
| Headless Service  | `nexus-headless`                                    |
| API Service       | `nexus-api`                                         |
| Consensus Service | `nexus-consensus`                                   |
| PVCs              | `nexus-data-nexus-cluster-0`, etc.                    |
| RDS Instance      | `nexus-coordination-cluster-db`                     |

## Common Issues & Solutions

### Pods Not Starting

```bash
kubectl describe pod nexus-cluster-0 -n coordination-system
kubectl logs nexus-cluster-0 -n coordination-system -c wait-for-db
```

### PVC Not Binding

```bash
kubectl get storageclass
kubectl describe pvc nexus-data-nexus-cluster-0 -n coordination-system
```

### Database Connection Failed

```bash
# Check security groups
aws rds describe-db-instances --db-instance-identifier nexus-coordination-cluster-db

# Test from pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -n coordination-system -- \
  psql -h <RDS_ENDPOINT> -U nexusadmin -d nexusdb
```

### Terraform State Locked

```bash
terraform force-unlock <LOCK_ID>
```

## Cost Breakdown

| Component            | Cost/Month (us-west-2) |
| -------------------- | ---------------------- |
| EKS Control Plane    | $73                    |
| EC2 (3x t3.large)    | $190                   |
| RDS (db.t3.large MA) | $290                   |
| NAT Gateways (3x)    | $100                   |
| EBS Volumes          | $20                    |
| **Total**            | **~$670**              |

## Next Steps After Deployment

1. ✅ Configure monitoring dashboards
2. ✅ Set up alerting rules
3. ✅ Implement backup strategy
4. ✅ Set up CI/CD pipeline
5. ✅ Configure DNS for ingress
6. ✅ Enable TLS certificates
7. ✅ Performance testing
8. ✅ Document runbooks
