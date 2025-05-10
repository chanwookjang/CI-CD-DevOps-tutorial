provider "aws" {
  region = "ap-northeast-2"
}

# EKS 클러스터 생성
resource "aws_eks_cluster" "prodxcloud-cluster-prod" {
  name     = "prodxcloud-cluster-prod"
  version  = "1.32"

  role_arn = aws_iam_role.eks.arn  # IAM 역할

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
  ami_type = "AL2_x86_64" # Amazon Linux 2

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = 1   # 프리 티어 무료 한도에 맞게 1대로 설정
    max_size     = 1
    min_size     = 1
  }

  tags = {
    Name = "eks-node-group"
  }
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "eks-node-"
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.eks_nodes_sg.id
  ]
  #아래서 생성한 유저데이터 사용
  user_data = base64encode(data.cloudinit_config.eks_node_user_data.rendered)

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8          # 원하는 디스크 크기(GB)
      volume_type = "gp3"      # 또는 "gp2"
      delete_on_termination = true
    }
  }
  
}

# MIME 멀티파트 형식으로 UserData 생성
data "cloudinit_config" "eks_node_user_data" {
  gzip          = false # gzip 비활성화 (기본값 true)
  base64_encode = false # base64 인코딩 비활성화

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      /etc/eks/bootstrap.sh ${aws_eks_cluster.prodxcloud-cluster-prod.name}
    EOF
  }
}