terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

variable "aws_region" {
  description = "AWS region for Trevoux lab"
  type        = string
  default     = "us-west-2"
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "eks-trevoux"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a"]
  public_subnets  = ["10.0.1.0/24"]
  private_subnets = ["10.0.2.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.3"

  cluster_name    = "eks-trevoux"
  cluster_version = "1.29"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      desired_size   = 1
      min_size       = 1
      max_size       = 2
    }
  }

  enable_irsa = true
}

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

resource "kubernetes_namespace" "trevoux" {
  metadata {
    name = "trevoux"
  }
}
