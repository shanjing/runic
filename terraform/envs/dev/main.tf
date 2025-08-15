# VPC Module
module "vpc" {
  source                  = "../../modules/vpc"
  name                    = var.name
  availability_zone       = var.availability_zone
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidr      = var.public_subnet_cidr
  enable_private_subnets  = var.enable_private_subnets
  enable_nat_gateway      = var.enable_nat_gateway
  tags = {
    Environment = "dev"
    Project     = "runic"
  }
}

# EC2 Module
module "ec2" {
  source        = "../../modules/ec2"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  name          = var.name
  subnet_id     = module.vpc.public_subnet_id
  vpc_id        = module.vpc.vpc_id
}

# EKS Module
module "eks" {
  count = var.enable_eks ? 1 : 0
  
  source = "../../modules/eks"
  
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = var.enable_private_subnets ? module.vpc.private_subnet_ids : [module.vpc.public_subnet_id]
  
  capacity_type   = var.eks_node_capacity_type
  instance_types  = var.eks_node_instance_types
  desired_size    = var.eks_node_desired_size
  max_size        = var.eks_node_max_size
  min_size        = var.eks_node_min_size
  
  enable_ssm_access = true
  
  tags = {
    Environment = "dev"
    Project     = "runic"
  }
}
