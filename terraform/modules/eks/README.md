# EKS Module

This Terraform module creates an Amazon EKS (Elastic Kubernetes Service) cluster with node groups, IAM roles, and security groups configured for production use.

## Features

- **EKS Cluster**: Managed Kubernetes control plane
- **Node Groups**: Auto-scaling worker nodes with spot/on-demand support
- **IRSA Support**: IAM Roles for Service Accounts with OIDC provider
- **Security Groups**: Network security for cluster and nodes
- **IAM Roles**: Proper permissions for cluster and node operations
- **Logging**: CloudWatch logging enabled for audit and debugging

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "my-eks-cluster"
  kubernetes_version = "1.29"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = [module.vpc.private_subnet_1_id, module.vpc.private_subnet_2_id]
  
  # Node group configuration
  capacity_type   = "SPOT"  # or "ON_DEMAND"
  instance_types  = ["t3.medium", "t3.small"]
  desired_size    = 2
  max_size        = 4
  min_size        = 1
  
  # Optional: Enable SSM access
  enable_ssm_access = true
  
  tags = {
    Environment = "dev"
    Project     = "runic"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| kubernetes_version | Kubernetes version for the EKS cluster | `string` | `"1.29"` | no |
| vpc_id | VPC ID where the EKS cluster will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` | n/a | yes |
| public_access_cidrs | List of CIDR blocks for public access to EKS cluster | `list(string)` | `["0.0.0.0/0"]` | no |
| capacity_type | Type of capacity for the node group (ON_DEMAND or SPOT) | `string` | `"ON_DEMAND"` | no |
| instance_types | List of instance types for the node group | `list(string)` | `["t3.medium"]` | no |
| desired_size | Desired number of worker nodes | `number` | `2` | no |
| max_size | Maximum number of worker nodes | `number` | `4` | no |
| min_size | Minimum number of worker nodes | `number` | `1` | no |
| enable_ssm_access | Enable SSM access for node groups | `bool` | `false` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | EKS cluster ID |
| cluster_arn | EKS cluster ARN |
| cluster_endpoint | EKS cluster endpoint |
| cluster_name | EKS cluster name |
| cluster_version | EKS cluster version |
| cluster_certificate_authority_data | EKS cluster certificate authority data |
| cluster_oidc_issuer_url | EKS cluster OIDC issuer URL |
| cluster_oidc_provider_arn | EKS cluster OIDC provider ARN |
| node_group_id | EKS node group ID |
| node_group_arn | EKS node group ARN |
| node_group_status | EKS node group status |
| cluster_role_arn | EKS cluster IAM role ARN |
| node_group_role_arn | EKS node group IAM role ARN |
| cluster_security_group_id | EKS cluster security group ID |
| nodes_security_group_id | EKS nodes security group ID |
| kubeconfig_command | Command to configure kubectl for the EKS cluster |
| cluster_info | Complete cluster information |

## Post-Deployment Steps

1. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --region us-west-2 --name my-eks-cluster
   ```

2. **Verify cluster access**:
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

3. **Install add-ons** (optional):
   ```bash
   # AWS Load Balancer Controller
   kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
   
   # Metrics Server
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

## Security Features

- **IRSA**: IAM Roles for Service Accounts enabled
- **Network Security**: Security groups with least privilege access
- **Encryption**: EBS volumes encrypted at rest
- **Logging**: CloudWatch logging for audit trails
- **SSM Access**: Optional Systems Manager access for troubleshooting

## Cost Optimization

- **Spot Instances**: Use `capacity_type = "SPOT"` for cost savings
- **Auto Scaling**: Configure min/max sizes for workload optimization
- **Instance Types**: Choose appropriate instance types for your workload

## Troubleshooting

### Common Issues

1. **Node group fails to create**:
   - Check IAM role permissions
   - Verify subnet configuration
   - Ensure security groups allow necessary traffic

2. **Cannot access cluster**:
   - Verify kubectl configuration
   - Check security group rules
   - Ensure VPC has internet connectivity

3. **Pods stuck in pending**:
   - Check node group capacity
   - Verify resource requests/limits
   - Check for taints and tolerations

### Useful Commands

```bash
# Check cluster status
aws eks describe-cluster --name my-eks-cluster

# Check node group status
aws eks describe-nodegroup --cluster-name my-eks-cluster --nodegroup-name my-eks-cluster-node-group

# Get cluster logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/my-eks-cluster
```
