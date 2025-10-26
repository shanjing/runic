terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# -----------------------------------------------------------
#  VPC: single AZ, minimal NAT cost, ready for expansion
# -----------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  name                   = "trevoux"
  vpc_cidr               = "10.0.0.0/16"
  public_subnet_cidr     = "10.0.1.0/24"
  availability_zone      = "us-west-2a"
  availability_zones     = ["us-west-2a"]
  enable_private_subnets = true
  private_subnet_cidrs   = ["10.0.2.0/24"]
  enable_nat_gateway     = false

  tags = {
    Environment = "dev"
    Project     = "trevoux"
  }
}

# -----------------------------------------------------------
#  EKS cluster: 1 node, IRSA enabled, ready for addons
# -----------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "trevoux"
  kubernetes_version = "1.29"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  instance_types = ["t3.small"]
  desired_size   = 1
  min_size       = 1
  max_size       = 2

  tags = {
    Environment = "dev"
    Project     = "trevoux"
  }
}

# -----------------------------------------------------------
#  Kubernetes provider uses module outputs, not data source
# -----------------------------------------------------------
data "aws_eks_cluster" "trevoux" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "trevoux" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.trevoux.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.trevoux.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.trevoux.token
}

# -----------------------------------------------------------
#  Optional namespace placeholder for future add-ons
# -----------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [module.eks]
}
