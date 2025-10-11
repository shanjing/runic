# Nexus (State Coordination Service) Infrastructure

This directory contains Terraform configurations for deploying the Nexus infrastructure on AWS EKS.

## Architecture Overview

The Nexus infrastructure consists of:

- **EKS Cluster**: Kubernetes cluster for running Nexus workloads
- **VPC**: Network infrastructure with public and private subnets across 3 AZs
- **RDS PostgreSQL**: Multi-AZ database for state ledger
- **AWS KMS**: Encryption key management
- **IAM Roles**: IRSA (IAM Roles for Service Accounts) for secure AWS resource access

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5.0
3. **kubectl** for Kubernetes management
4. **helm** for Kubernetes package management

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform/envs/scs
terraform init
```

### 2. Review Configuration

Review and modify `terraform.tfvars` if needed:

```bash
cat terraform.tfvars
```

### 3. Plan Infrastructure

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

This will create:

- VPC with networking
- EKS cluster with managed node group
- RDS PostgreSQL database (Multi-AZ)
- KMS encryption keys
- IAM roles and policies
- Kubernetes namespace `coordination-system`

### 5. Configure kubectl

After deployment, configure kubectl to access the cluster:

```bash
aws eks update-kubeconfig --region us-west-2 --name scs-coordination-cluster
```

### 6. Verify Deployment

```bash
kubectl get nodes
kubectl get namespace coordination-system
```

## Configuration Variables

Key variables you can customize in `terraform.tfvars`:

| Variable                | Description             | Default                    |
| ----------------------- | ----------------------- | -------------------------- |
| `aws_region`            | AWS region              | `us-west-2`                |
| `cluster_name`          | EKS cluster name        | `scs-coordination-cluster` |
| `cluster_version`       | Kubernetes version      | `1.28`                     |
| `eks_node_desired_size` | Desired number of nodes | `3`                        |
| `rds_instance_class`    | RDS instance type       | `db.t3.large`              |
| `rds_multi_az`          | Enable Multi-AZ         | `true`                     |
| `enable_kms`            | Enable KMS encryption   | `true`                     |

## Resources Created

### Network Resources

- 1 VPC
- 3 Public subnets
- 3 Private subnets
- 3 NAT Gateways
- Internet Gateway
- Route tables and associations

### Compute Resources

- EKS Control Plane
- EKS Managed Node Group (3-10 nodes)
- Auto-scaling configuration

### Database Resources

- RDS PostgreSQL instance (Multi-AZ)
- DB subnet group
- Security groups
- AWS Secrets Manager secret for credentials

### Security Resources

- KMS key for encryption
- IAM roles for IRSA
- Security groups
- Network policies (configured via Kubernetes)

### Kubernetes Resources

- Namespace: `coordination-system`
- Service Account: `scs-service-account` (with IRSA)

## Accessing RDS Credentials

RDS credentials are stored in AWS Secrets Manager:

```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw rds_credentials_secret_arn) \
  --query SecretString \
  --output text | jq .
```

## Outputs

Important outputs:

```bash
# Get EKS cluster endpoint
terraform output eks_cluster_endpoint

# Get RDS endpoint
terraform output rds_endpoint

# Get KMS key ARN
terraform output kms_key_arn

# Get kubectl configuration command
terraform output configure_kubectl
```

## Security Considerations

1. **Encryption**: All data is encrypted at rest using KMS
2. **Network Isolation**: RDS and EKS nodes are in private subnets
3. **IAM Roles**: Service accounts use IRSA for least-privilege access
4. **Secrets Management**: Credentials stored in AWS Secrets Manager
5. **Backup**: RDS has 7-day backup retention by default
6. **Deletion Protection**: RDS has deletion protection enabled

## Cost Estimation

Approximate monthly costs (us-west-2):

- EKS Control Plane: ~$73
- EC2 Nodes (3x t3.large): ~$190
- RDS (db.t3.large Multi-AZ): ~$290
- NAT Gateways (3x): ~$100
- EBS Volumes: ~$20
- Data Transfer: Variable

**Total**: ~$670/month (baseline, excluding data transfer)

## Cleanup

To destroy all resources:

```bash
# Disable deletion protection on RDS first
aws rds modify-db-instance \
  --db-instance-identifier scs-coordination-cluster-db \
  --no-deletion-protection

# Then destroy
terraform destroy
```

⚠️ **Warning**: This will delete all data permanently!

## Remote State (Optional)

To enable remote state management, uncomment the backend configuration in `provider.tf` and create the S3 bucket and DynamoDB table:

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket scs-terraform-state \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket scs-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locks
aws dynamodb create-table \
  --table-name scs-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2
```

## Troubleshooting

### EKS cluster not accessible

```bash
aws eks update-kubeconfig --region us-west-2 --name scs-coordination-cluster
kubectl get svc
```

### RDS connection issues

Check security groups and ensure EKS nodes can reach RDS:

```bash
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql -h <RDS_ENDPOINT> -U scsadmin -d scsdb
```

### Terraform state issues

If you encounter state lock issues:

```bash
# List locks
aws dynamodb scan --table-name scs-terraform-locks

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

## Next Steps

After infrastructure is deployed:

1. Deploy Nexus application using Helm charts (see `kubernetes/helm/charts/nexus/`)
2. Configure monitoring and observability
3. Set up CI/CD pipelines
4. Configure backup and disaster recovery procedures
5. Implement security scanning and compliance checks

## Support

For issues and questions, refer to:

- Architecture documentation: `docs/nexus-architecture.md`
- Infrastructure status: `docs/infrastructure-status.md`
