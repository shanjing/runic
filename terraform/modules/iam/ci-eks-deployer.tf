#############################################
# CI/CD EKS Deployer IAM Role (for GitHub Actions)
#############################################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Environment = "dev"
    Project     = "trevoux"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role" "ci_eks_deployer" {
  name = "ci-eks-deployer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::403692606562:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" = "repo:shanjing/runic:ref:refs/heads/trevoux"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "dev"
    Project     = "trevoux"
    ManagedBy   = "terraform"
  }
}

# --- Attach AWS-managed policies for EKS deployment permissions ---
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.ci_eks_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.ci_eks_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.ci_eks_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ci_eks_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

