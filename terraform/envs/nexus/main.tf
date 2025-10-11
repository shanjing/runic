# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets

  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size
  node_disk_size      = var.eks_node_disk_size

  enable_irsa = var.enable_irsa

  tags = var.tags
}

# KMS Key for encryption
resource "aws_kms_key" "nexus" {
  count = var.enable_kms ? 1 : 0

  description             = "KMS key for Nexus encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-kms"
    }
  )
}

resource "aws_kms_alias" "nexus" {
  count = var.enable_kms ? 1 : 0

  name          = "alias/${var.cluster_name}-key"
  target_key_id = aws_kms_key.scs[0].key_id
}

# RDS PostgreSQL Instance
resource "aws_db_subnet_group" "nexus" {
  count = var.enable_rds ? 1 : 0

  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-db-subnet-group"
    }
  )
}

resource "aws_security_group" "rds" {
  count = var.enable_rds ? 1 : 0

  name_prefix = "${var.cluster_name}-rds-"
  description = "Security group for Nexus RDS instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-rds-sg"
    }
  )
}

resource "random_password" "rds_password" {
  count = var.enable_rds ? 1 : 0

  length  = 32
  special = true
}

resource "aws_db_instance" "nexus" {
  count = var.enable_rds ? 1 : 0

  identifier     = "${var.cluster_name}-db"
  engine         = "postgres"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage = var.rds_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = var.enable_kms ? aws_kms_key.scs[0].arn : null

  db_name  = "nexusdb"
  username = "nexusadmin"
  password = random_password.rds_password[0].result

  db_subnet_group_name   = aws_db_subnet_group.scs[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]

  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.cluster_name}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-db"
    }
  )
}

# Store RDS credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "rds_credentials" {
  count = var.enable_rds ? 1 : 0

  name_prefix = "${var.cluster_name}-rds-credentials-"
  description = "RDS credentials for Nexus database"
  kms_key_id  = var.enable_kms ? aws_kms_key.scs[0].id : null

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  count = var.enable_rds ? 1 : 0

  secret_id = aws_secretsmanager_secret.rds_credentials[0].id
  secret_string = jsonencode({
    username = aws_db_instance.scs[0].username
    password = random_password.rds_password[0].result
    engine   = "postgres"
    host     = aws_db_instance.scs[0].address
    port     = aws_db_instance.scs[0].port
    dbname   = aws_db_instance.scs[0].db_name
  })
}

# IAM role for Nexus service account
resource "aws_iam_role" "nexus_service_account" {
  count = var.enable_irsa ? 1 : 0

  name = "${var.cluster_name}-scs-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:coordination-system:nexus-service-account"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for Nexus service account - access to KMS and Secrets Manager
resource "aws_iam_role_policy" "nexus_service_account" {
  count = var.enable_irsa ? 1 : 0

  name = "${var.cluster_name}-scs-sa-policy"
  role = aws_iam_role.nexus_service_account[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = var.enable_kms ? [aws_kms_key.scs[0].arn] : []
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.enable_rds ? [aws_secretsmanager_secret.rds_credentials[0].arn] : []
      }
    ]
  })
}

# Create namespace for Nexus
resource "kubernetes_namespace" "coordination_system" {
  metadata {
    name = "coordination-system"
    labels = {
      name = "coordination-system"
      app  = "nexus"
    }
  }

  depends_on = [module.eks]
}

# Create service account with IRSA
resource "kubernetes_service_account" "nexus" {
  count = var.enable_irsa ? 1 : 0

  metadata {
    name      = "scs-service-account"
    namespace = kubernetes_namespace.coordination_system.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.nexus_service_account[0].arn
    }
  }

  depends_on = [module.eks]
}

