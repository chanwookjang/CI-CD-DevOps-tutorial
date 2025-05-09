provider "aws" {
  region = "ap-northeast-2"
}

# EKS 클러스터 생성
resource "aws_eks_cluster" "prodxcloud-cluster-prod" {
  name     = "prodxcloud-cluster-prod"
  version  = "1.32"

  role_arn = aws_iam_role.eks.arn  # IAM 역할은 별도로 정의해야 합니다.

  vpc_config {
    subnet_ids = [
    aws_subnet.private-ap-northeast-2a.id,
    aws_subnet.private-ap-northeast-2b.id,
    ]  # 실제 사용할 서브넷 ID 배열
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Environment = "prod"
    Name        = "prodxcloud-cluster-prod"
  }
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.prodxcloud-cluster-prod.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private-ap-northeast-2a.id, aws_subnet.private-ap-northeast-2b.id]

  scaling_config {
    desired_size = 1   # 프리 티어 무료 한도에 맞게 1대로 설정
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.micro"]   # 프리 티어 지원 인스턴스 타입
  ami_type       = "AL2_x86_64"
  disk_size      = 8              # 프리 티어 EBS 30GB 내에서 8GB만 사용

  tags = {
    Name = "eks-node-group"
  }
}
