# VPC Module
module "vpc" {
  source             = "../../modules/vpc"
  name               = var.name
  availability_zone  = var.availability_zone
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
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
