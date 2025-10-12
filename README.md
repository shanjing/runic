# Runic

A modern infrastructure and application platform built with Terraform, Kubernetes, and Helm. Nexus is in an active development stage, with gradual improvements underway.

> 📖 **Learn more about Runic**: See [ABOUT.md](./ABOUT.md) for project vision and creator background.

## 🏗️ Project Structure

```
Runic/
├── docs/                    # Documentation
│   └── infrastructure-status.md
├── kubernetes/              # Kubernetes resources
│   ├── helm/               # Helm charts
│   ├── manifests/          # Kubernetes YAML manifests
│   ├── configs/            # Kubernetes configurations
│   └── scripts/            # Kubernetes-related scripts
├── terraform/              # Infrastructure as Code
│   ├── modules/            # Reusable Terraform modules
│   │   ├── ec2/           # EC2 instance module
│   │   └── vpc/           # VPC and networking module
│   └── envs/              # Environment-specific configurations
│       └── dev/           # Development environment
├── scripts/                # Utility scripts
└── .vscode/               # VS Code workspace settings
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials (see [AWS Authentication](./aws/README.md))
- Terraform installed
- kubectl installed (for Kubernetes management)

### Development Environment Setup

1. **Authenticate with AWS**:

   ```bash
   # Authenticate with MFA and assume admin role
   source aws/assume-role.sh

   # Verify authentication
   aws sts get-caller-identity
   ```

2. **Deploy Infrastructure**:

   ```bash
   cd terraform/envs/dev
   terraform init
   terraform plan
   terraform apply
   ```

3. **Access EKS Cluster**:

   ```bash
   # Configure kubectl for EKS
   aws eks update-kubeconfig --region us-west-2 --name runic-dev-cluster

   # Verify cluster access
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

4. **Deploy Applications**:

   ```bash
   # Using Helm charts
   cd kubernetes/helm
   helm install my-app ./my-app-chart

   # Using Kubernetes manifests
   kubectl apply -f kubernetes/manifests/
   ```

## 📋 Current Status

### Development Environment

- ✅ **Infrastructure**: EKS cluster with auto-scaling worker nodes
- ✅ **Kubernetes**: Managed EKS cluster (v1.29) with IRSA support
- ✅ **Security**: IAM roles, security groups, and MFA authentication
- ✅ **Cost Optimized**: Spot instances, minimal nodes, no NAT Gateway
- ✅ **Networking**: VPC with public and private subnets

### Planned Production

- 🔄 **Multi-AZ**: High availability across availability zones
- 🔄 **Load Balancer**: ALB for external traffic
- 🔄 **Bastion Host**: Secure SSH access to private nodes
- 🔄 **Monitoring**: Prometheus, Grafana, and CloudWatch integration
- 🔄 **Data Layer**: RDS, MSK, and S3 integration

## 🛠️ Technology Stack

- **Infrastructure**: Terraform, AWS EKS
- **Container Runtime**: containerd
- **Orchestration**: Kubernetes 1.29 (EKS)
- **Networking**: AWS VPC CNI
- **Package Management**: Helm
- **Security**: AWS Security Groups, IAM, IRSA, MFA Authentication

## �� Documentation

- [About Runic](./ABOUT.md) - Project vision and creator background
- [Infrastructure Status](./docs/infrastructure-status.md) - Detailed infrastructure overview
- [Kubernetes Setup](./kubernetes/README.md) - Kubernetes-specific documentation
- [AWS Authentication](./aws/README.md) - AWS CLI authentication with MFA

## 🔧 Development

### AWS Authentication

Before working with Terraform or AWS resources, authenticate with AWS:

```bash
# Authenticate with MFA and assume admin role
source aws/assume-role.sh

# Verify authentication
aws sts get-caller-identity
```

### Usage with Terraform

Once authenticated, you can use Terraform with the temporary credentials:

```bash
# Navigate to your Terraform directory
cd terraform/envs/dev

# Initialize and plan
terraform init
terraform plan

# Apply changes
terraform apply
```

### Usage with AWS CLI

After authentication, all AWS CLI commands will use the temporary credentials:

```bash
# List S3 buckets
aws s3 ls

# Check current identity
aws sts get-caller-identity

# List EC2 instances
aws ec2 describe-instances
```

### Adding New Kubernetes Resources

1. **Helm Charts**: Place in `kubernetes/helm/`
2. **Raw Manifests**: Place in `kubernetes/manifests/`
3. **Configurations**: Place in `kubernetes/configs/`

### Adding New Infrastructure

1. **Terraform Modules**: Place in `terraform/modules/`
2. **Environment Configs**: Place in `terraform/envs/<environment>/`

## 🔄 Optional: Legacy Kubeadm Setup

For learning purposes or if you prefer a self-managed Kubernetes cluster, you can use the legacy kubeadm setup:

### Prerequisites

- EC2 instance with Ubuntu 22.04
- SSH access to the instance

### Setup Instructions

1. **Deploy EC2 Infrastructure**:

   ```bash
   cd terraform/envs/dev
   # Comment out EKS module in main.tf
   terraform apply -target=module.vpc -target=module.ec2
   ```

2. **SSH to Instance and Bootstrap**:

   ```bash
   # Get SSH command
   terraform output ssh_command
   
   # SSH to instance
   ssh -i ~/.ssh/id_rsa ubuntu@<instance-ip>
   
   # The bootstrap script runs automatically via user_data
   # Monitor progress:
   sudo tail -f /var/log/cloud-init-output.log
   ```

3. **Access Cluster**:

   ```bash
   # Copy kubeconfig from instance
   scp -i ~/.ssh/id_rsa ubuntu@<instance-ip>:/home/ubuntu/.kube/config-remote ~/.kube/config
   
   # Verify access
   kubectl get nodes
   ```

### Features

- **Single-node cluster** with containerd and Flannel CNI
- **Metrics Server** for resource monitoring
- **Test deployment** (nginx) included
- **Cost**: ~$15/month for t3.medium instance

### Limitations

- **Single point of failure** (one node)
- **Manual management** (updates, scaling)
- **Limited security** (no IRSA, basic RBAC)
- **No auto-scaling** capabilities

## 📊 Cost Management

### Development Environment Costs

| Setup | Hourly Cost | Monthly Cost (Your Usage) | Monthly Cost (24/7) |
|-------|-------------|---------------------------|-------------------|
| **EKS (Recommended)** | $0.17/hour | $4-8/month | $125/month |
| **Kubeadm (Legacy)** | $0.04/hour | $1-2/month | $30/month |

### Cost Optimization Features

- **Spot Instances**: 60-90% savings on compute costs
- **Minimal Nodes**: 1 worker node with auto-scaling (0-2 nodes)
- **No NAT Gateway**: Saves $0.05/hour (~$36/month if running 24/7)
- **EKS Control Plane**: $0.10/hour (always running)

### Production Environment

- **Multi-AZ**: High availability across availability zones
- **Load Balancers**: ALB/NLB for external traffic
- **Monitoring**: CloudWatch, Prometheus, Grafana
- **Estimated Cost**: $200-500+/month

### Cost Monitoring

- Use AWS Cost Explorer to track expenses
- Set up billing alerts for budget management
- Monitor resource usage with CloudWatch

## 🔒 Security

- Follow AWS Well-Architected Framework
- Implement least privilege access
- Regular security updates
- Network segmentation

---

_Last Updated: June 28, 2024_
