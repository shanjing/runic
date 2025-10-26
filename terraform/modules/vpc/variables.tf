variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones (e.g., [\"us-west-2a\", \"us-west-2b\"])"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs (one per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs (one per AZ)"
  type        = list(string)
}

variable "enable_private_subnets" {
  description = "Whether to create private subnets"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Whether to enable a NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

