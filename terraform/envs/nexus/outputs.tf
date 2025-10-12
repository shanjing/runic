output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_certificate_authority" {
  description = "EKS cluster certificate authority"
  value       = module.eks.cluster_certificate_authority
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.eks.node_security_group_id
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "kms_key_id" {
  description = "KMS key ID for Nexus encryption"
  value       = var.enable_kms ? aws_kms_key.scs[0].id : null
}

output "kms_key_arn" {
  description = "KMS key ARN for Nexus encryption"
  value       = var.enable_kms ? aws_kms_key.scs[0].arn : null
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.enable_rds ? aws_db_instance.scs[0].endpoint : null
  sensitive   = true
}

output "rds_address" {
  description = "RDS instance address"
  value       = var.enable_rds ? aws_db_instance.scs[0].address : null
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.enable_rds ? aws_db_instance.scs[0].port : null
}

output "rds_database_name" {
  description = "RDS database name"
  value       = var.enable_rds ? aws_db_instance.scs[0].db_name : null
}

output "rds_credentials_secret_arn" {
  description = "ARN of the secret containing RDS credentials"
  value       = var.enable_rds ? aws_secretsmanager_secret.rds_credentials[0].arn : null
  sensitive   = true
}

output "nexus_service_account_role_arn" {
  description = "IAM role ARN for Nexus service account"
  value       = var.enable_irsa ? aws_iam_role.nexus_service_account[0].arn : null
}

output "coordination_namespace" {
  description = "Kubernetes namespace for Nexus"
  value       = kubernetes_namespace.coordination_system.metadata[0].name
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}

