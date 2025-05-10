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
    security_group_ids = [
      aws_security_group.eks_cluster_sg.id
    ] # EKS 클러스터에 연결할 보안 그룹 연결
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Environment = "prod"
    Name        = "prodxcloud-cluster-prod"
  }
}

# 노드그룹 생성
# 강제 종료 시 aws eks delete-nodegroup --cluster-name prodxcloud-cluster-prod --nodegroup-name eks-node-group --region ap-northeast-2 --no-paginate
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.prodxcloud-cluster-prod.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private-ap-northeast-2a.id, aws_subnet.private-ap-northeast-2b.id]

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 1   # 프리 티어 무료 한도에 맞게 1대로 설정
    max_size     = 1
    min_size     = 1
  }

     # 프리 티어 지원 인스턴스 타입
  ami_type = "CUSTOM"
  #instance_types = ["t3.micro"]
  
  tags = {
    Name = "eks-node-group"
  }
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "eks-node-"
  image_id      = data.aws_ami.eks_worker.id # EKS 공식 AMI 또는 원하는 AMI
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.eks_nodes_sg.id
  ]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8          # 원하는 디스크 크기(GB)
      volume_type = "gp3"      # 또는 "gp2"
      delete_on_termination = true
    }
  }
  
}