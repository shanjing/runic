# -----------------------------------------------------------
#  VPC: 2 AZs, NAT ENABLED (for EKS node access)
# -----------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  name               = "trevoux"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]

  # Two public + two private subnets (one pair per AZ)
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24"]

  # ✅ NAT gateway enabled for private subnet Internet access
  enable_private_subnets = true
  enable_nat_gateway     = true

  tags = {
    Environment = "dev"
    Project     = "trevoux"
  }
}

module "ci_iam" {
  source = "../../modules/iam"
}

# -----------------------------------------------------------
#  EKS: Managed cluster across 2 AZs
# -----------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "trevoux"
  kubernetes_version = "1.29"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids  # stays private, now with NAT

  instance_types = ["t3.small"]
  desired_size   = 2   # one node per AZ
  min_size       = 1
  max_size       = 3

  tags = {
    Environment = "dev"
    Project     = "trevoux"
  }
}

# -----------------------------------------------------------
#  Example Namespace (created after cluster is ready)
# -----------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [module.eks]
}

