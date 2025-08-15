output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

output "kubeconfig_command" {
  description = "Command to copy kubeconfig from the instance"
  value       = module.ec2.kubeconfig_command
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = module.ec2.ssh_command
}

output "kubernetes_api_url" {
  description = "Kubernetes API server URL"
  value       = module.ec2.kubernetes_api_url
}

output "bootstrap_monitoring_instructions" {
  description = "Instructions for monitoring the bootstrap process"
  value       = module.ec2.bootstrap_monitoring_instructions
}

# EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = var.enable_eks ? module.eks[0].cluster_id : null
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = var.enable_eks ? module.eks[0].cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "eks_kubeconfig_command" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = var.enable_eks ? module.eks[0].kubeconfig_command : null
}

output "eks_cluster_info" {
  description = "Complete EKS cluster information"
  value       = var.enable_eks ? module.eks[0].cluster_info : null
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA"
  value       = var.enable_eks ? module.eks[0].cluster_oidc_provider_arn : null
}
