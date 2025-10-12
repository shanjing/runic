# Nexus Deployment Guide

This guide walks through deploying the Nexus Coordination Service infrastructure to AWS.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Deployment Steps](#detailed-deployment-steps)
4. [Configuration](#configuration)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Cleanup](#cleanup)

## Prerequisites

### Required Tools

Install the following tools before deployment:

```bash
# AWS CLI
brew install awscli

# Terraform
brew install terraform

# kubectl
brew install kubectl

# Helm
brew install helm

# jq (JSON processor)
brew install jq
```

### AWS Configuration

1. **Configure AWS credentials:**

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-west-2)
```

2. **Verify AWS access:**

```bash
aws sts get-caller-identity
```

### Required AWS Permissions

Your AWS user/role needs permissions for:

- EC2 (VPC, Security Groups, Instances)
- EKS (Cluster, Node Groups)
- RDS (Database Instances)
- KMS (Key Management)
- IAM (Roles, Policies)
- Secrets Manager
- CloudWatch Logs

## Quick Start

### Automated Deployment

The fastest way to deploy Nexus:

```bash
# Clone the repository
cd /path/to/Runic

# Run the deployment script
./scripts/deploy-nexus.sh
```

This will:

1. ✅ Check all prerequisites
2. 🏗️ Deploy Terraform infrastructure (VPC, EKS, RDS, KMS)
3. ⚙️ Configure kubectl
4. 🚀 Deploy Helm chart
5. ✓ Verify deployment

### Dry Run

To see what will be deployed without making changes:

```bash
./scripts/deploy-nexus.sh --dry-run
```

## Detailed Deployment Steps

### Step 1: Deploy Infrastructure with Terraform

```bash
cd terraform/envs/nexus

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the changes
terraform apply
```

**What gets created:**

- VPC with 3 public and 3 private subnets across 3 AZs
- NAT Gateways for private subnet internet access
- EKS cluster with managed node group (3-10 nodes)
- RDS PostgreSQL Multi-AZ instance
- KMS keys for encryption
- IAM roles for IRSA (IAM Roles for Service Accounts)
- Security groups and network ACLs

**Time estimate:** 15-20 minutes

### Step 2: Configure kubectl

```bash
# Get cluster name from Terraform
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name $CLUSTER_NAME

# Verify connection
kubectl get nodes
```

### Step 3: Retrieve Database Credentials

```bash
# Get RDS credentials from AWS Secrets Manager
SECRET_ARN=$(terraform output -raw rds_credentials_secret_arn)

aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text | jq .
```

Save these credentials for the Helm deployment.

### Step 4: Deploy Application with Helm

#### Option A: Install from Repository (Recommended)

```bash
# Clone the repository if not already cloned
git clone https://github.com/shanjing/runic.git
cd runic

# Install directly from repository path
helm install nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --create-namespace \
  --set secrets.database.host="your-rds-endpoint.us-west-2.rds.amazonaws.com" \
  --set secrets.database.password="YOUR_PASSWORD_FROM_SECRETS_MANAGER"
```

#### Option B: Install with Custom Values File

Create a `values-custom.yaml` file:

```yaml
# values-custom.yaml
image:
  repository: ghcr.io/shanjing/nexus
  tag: v1.0.0

secrets:
  database:
    host: "your-rds-endpoint.us-west-2.rds.amazonaws.com"
    port: "5432"
    name: "nexusdb"
    user: "nexusadmin"
    password: "YOUR_PASSWORD_FROM_SECRETS_MANAGER"

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/nexus-sa-role"

ingress:
  hosts:
    - host: nexus-api.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
```

Deploy with Helm:

```bash
# From repository root
helm install nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --create-namespace \
  -f values-custom.yaml

# Or if you're in the chart directory
cd kubernetes/helm/charts/nexus
helm install nexus . \
  -n coordination-system \
  --create-namespace \
  -f values-custom.yaml

# Or upgrade if already installed
helm upgrade nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  -f values-custom.yaml
```

### Step 5: Wait for Pods

```bash
# Watch pods starting
kubectl get pods -n coordination-system -w

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod \
  -l app=nexus \
  -n coordination-system \
  --timeout=300s
```

## Configuration

### Environment-Specific Configuration

Create environment-specific values files:

**Production:**

```yaml
# values-production.yaml
replicaCount: 5

resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    cpu: 4000m
    memory: 8Gi

persistence:
  size: 50Gi
  storageClassName: io2

config:
  app:
    logLevel: warn
```

**Development:**

```yaml
# values-dev.yaml
replicaCount: 1

resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 2Gi

persistence:
  size: 10Gi
```

### Terraform Variables

Customize via `terraform.tfvars`:

```hcl
# Custom configuration
aws_region = "us-east-1"
cluster_name = "nexus-prod-cluster"
eks_node_desired_size = 5
rds_instance_class = "db.r5.xlarge"
```

## Verification

### Check Infrastructure

```bash
# Check all resources
kubectl get all -n coordination-system

# Check StatefulSet
kubectl get statefulset -n coordination-system

# Check PVCs
kubectl get pvc -n coordination-system

# Check services
kubectl get svc -n coordination-system

# Check ingress
kubectl get ingress -n coordination-system
```

### Test API Endpoint

```bash
# Port-forward to local machine
kubectl port-forward svc/nexus-api 8080:8080 -n coordination-system

# In another terminal, test the API
curl http://localhost:8080/health/ready
curl http://localhost:8080/health/live
```

### Check Logs

```bash
# View logs from all pods
kubectl logs -f statefulset/nexus-cluster -n coordination-system

# View logs from specific pod
kubectl logs -f nexus-cluster-0 -n coordination-system

# View logs from previous pod instance
kubectl logs nexus-cluster-0 -n coordination-system --previous
```

### Check Metrics

```bash
# Port-forward metrics endpoint
kubectl port-forward svc/nexus-api 9091:9091 -n coordination-system

# View metrics
curl http://localhost:9091/metrics
```

### Database Connection Test

```bash
# Exec into a pod
kubectl exec -it nexus-cluster-0 -n coordination-system -- sh

# Test DB connection (if psql is available)
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

## Troubleshooting

### Pods Not Starting

```bash
# Describe pod to see events
kubectl describe pod nexus-cluster-0 -n coordination-system

# Check events
kubectl get events -n coordination-system --sort-by='.lastTimestamp'

# Check init container logs
kubectl logs nexus-cluster-0 -n coordination-system -c wait-for-db
```

### PVC Issues

```bash
# Check PVC status
kubectl describe pvc nexus-data-nexus-cluster-0 -n coordination-system

# Check storage class
kubectl get storageclass

# List available volumes
kubectl get pv
```

### Database Connection Issues

```bash
# Verify RDS is accessible
aws rds describe-db-instances --db-instance-identifier nexus-coordination-cluster-db

# Check security groups
# Ensure EKS node security group can access RDS on port 5432

# Test from pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -n coordination-system -- \
  psql -h YOUR_RDS_ENDPOINT -U nexusadmin -d nexusdb
```

### Terraform Issues

```bash
# Refresh state
terraform refresh

# Show current state
terraform show

# Unlock state (if locked)
terraform force-unlock LOCK_ID
```

### Helm Issues

```bash
# List releases
helm list -n coordination-system

# Get release details
helm get all nexus -n coordination-system

# Rollback to previous version
helm rollback nexus -n coordination-system

# Debug template rendering
helm template nexus . -n coordination-system --debug
```

## Cleanup

### Quick Cleanup

```bash
# Run the destroy script
./scripts/destroy-nexus.sh
```

### Manual Cleanup

If you prefer manual cleanup:

```bash
# 1. Uninstall Helm release
helm uninstall nexus -n coordination-system

# 2. Delete PVCs (not deleted by Helm)
kubectl delete pvc -n coordination-system -l app=nexus

# 3. Delete namespace
kubectl delete namespace coordination-system

# 4. Disable RDS deletion protection
aws rds modify-db-instance \
  --db-instance-identifier nexus-coordination-cluster-db \
  --no-deletion-protection \
  --apply-immediately

# 5. Destroy Terraform infrastructure
cd terraform/envs/nexus
terraform destroy
```

**⚠️ Warning:** This permanently deletes all data!

## Cost Optimization

### Development Environment

For development, use smaller resources:

```hcl
# terraform.tfvars
eks_node_instance_types = ["t3.medium"]
eks_node_desired_size = 1
rds_instance_class = "db.t3.small"
rds_multi_az = false
```

### Production Environment

For production, use appropriate sizing:

```hcl
# terraform.tfvars
eks_node_instance_types = ["m5.xlarge"]
eks_node_desired_size = 3
rds_instance_class = "db.r5.large"
rds_multi_az = true
```

### Stop Development Environment

To save costs when not in use:

```bash
# Stop EKS node group (via AWS Console or CLI)
# Stop RDS instance
aws rds stop-db-instance --db-instance-identifier nexus-coordination-cluster-db
```

## Security Best Practices

1. **Use External Secrets Operator** instead of storing secrets in Helm values
2. **Enable pod security policies** and admission controllers
3. **Use private ECR** for container images
4. **Enable encryption** at rest and in transit
5. **Rotate credentials** regularly
6. **Enable audit logging** in EKS
7. **Use VPN or bastion** for kubectl access
8. **Enable WAF** on ALB ingress
9. **Implement network policies** to restrict pod-to-pod communication
10. **Regular security scanning** of container images

## Next Steps

After successful deployment:

1. **Set up monitoring**: Configure Prometheus and Grafana dashboards
2. **Set up alerting**: Configure alerts for critical metrics
3. **Set up CI/CD**: Automate deployments with GitOps (ArgoCD/Flux)
4. **Set up backup**: Configure automated backups for RDS and PVCs
5. **Set up disaster recovery**: Document and test DR procedures
6. **Performance testing**: Load test the system
7. **Documentation**: Document your specific configurations and procedures

## Support

For issues and questions:

- Check the architecture documentation: `docs/nexus-architecture.md`
- Review Terraform outputs: `terraform output`
- Check Helm values: `helm get values nexus -n coordination-system`
- View pod logs: `kubectl logs -f statefulset/nexus-cluster -n coordination-system`
