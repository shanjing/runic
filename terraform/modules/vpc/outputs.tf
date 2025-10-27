# -----------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if created)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}
