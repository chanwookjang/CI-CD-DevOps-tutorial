terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. VPC & Subnet
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "eks-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  tags = { Name = "eks-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# 2. Security Groups
resource "aws_security_group" "eks_cluster" {
  name_prefix = "eks-cluster-sg-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. IAM Roles
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# 4. EKS Cluster
resource "aws_eks_cluster" "cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  
  vpc_config {
    subnet_ids = [aws_subnet.public.id]
    security_group_ids = [aws_security_group.eks_cluster.id]
  }
}

# 5. Node Group
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [aws_subnet.public.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t2.micro"]
    #런치템플릿으로 인터넷에서 접속 가능한 퍼블릭 ip 자동할당
    launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "eks-node-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true ## 얘 퍼블릭 ip 자동할당 핵심
    security_groups             = [aws_security_group.eks_cluster.id]
  }
}

# 6. ECR Repository (주석 해제시 생성)
/*
resource "aws_ecr_repository" "app" {
  name = "django-app"
}
*/

# EKS Cluster Role에 정책 연결 EKS 클러스터가 AWS 리소스 관리에 필요한 권한
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Node Role에 정책 연결 워커 노드가 EKS 클러스터와 통신하는 데 필요한 권한
resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
# ECR에서 이미지 풀(Pull) 권한
resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}