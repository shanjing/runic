# Runic

A modern infrastructure and application platform built with Terraform, Kubernetes, and Helm.

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

3. **Access Kubernetes Cluster**:

   ```bash
   # Get the SSH command from terraform output
   terraform output ssh_command

   # Copy kubeconfig to your local machine
   terraform output kubeconfig_command

   # Use kubectl locally
   export KUBECONFIG=./kubeconfig
   kubectl get nodes
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

- ✅ **Infrastructure**: Single EC2 instance (t3.micro) in us-west-2
- ✅ **Kubernetes**: Single-node cluster with containerd and Flannel CNI (v1.33.0)
- ✅ **Security**: Restrictive security groups with necessary ports open
- ✅ **Cost Optimized**: No NAT Gateway (~$32/month saved)

### Planned Production

- 🔄 **Multi-AZ**: High availability across availability zones
- 🔄 **Private Subnets**: Kubernetes nodes in private subnets
- 🔄 **Load Balancer**: ALB for external traffic
- 🔄 **Bastion Host**: Secure SSH access to private nodes
- 🔄 **NAT Gateway**: For private node internet access

## 🛠️ Technology Stack

- **Infrastructure**: Terraform, AWS
- **Container Runtime**: containerd
- **Orchestration**: Kubernetes 1.33.0
- **Networking**: Flannel CNI
- **Package Management**: Helm
- **Security**: AWS Security Groups, IAM, MFA Authentication

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

## 📊 Cost Management

- **Development**: ~$8-15/month
- **Production**: ~$200-500+/month
- **Monitoring**: Use AWS Cost Explorer

## 🔒 Security

- Follow AWS Well-Architected Framework
- Implement least privilege access
- Regular security updates
- Network segmentation

---

_Last Updated: June 28, 2024_
