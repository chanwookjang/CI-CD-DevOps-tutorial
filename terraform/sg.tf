#EKS 클러스터 SG
resource "aws_security_group" "eks_cluster_sg" {
  name   = "eks-cluster"
  vpc_id = aws_vpc.tenant_vpc.id
  # 인라인 규칙 없이 정의
}

# EKS 노드 SG (하나만 유지)
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-node-sg"
  description = "EKS worker node security group"
  vpc_id      = aws_vpc.tenant_vpc.id

  # SSH 접근 허용
  ingress {
  description = "Allow SSH"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # 실제 운영 환경에서는 IP 제한 권장
  }

  # 노드 간 통신 허용
  ingress {
    description = "Allow node-to-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # 필요시 외부에서 Load Balancer로 접근 허용
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
  description = "Allow HTTPS from VPC Endpoint"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
}

  # 아웃바운드: 모든 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  description = "Allow EKS/EC2 API"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"] # VPC CIDR (VPC 엔드포인트용)
  }
  tags = {
    Name = "eks-node-sg"
  }
}

# 클러스터 SG에서 노드 SG로 443 포트 허용
resource "aws_security_group_rule" "nodes_from_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}

# 필요시 노드 SG에서 클러스터 SG로 443 포트 허용
resource "aws_security_group_rule" "cluster_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
}

# 노드 SG에서 kubelet 포트 허용 (10250)
resource "aws_security_group_rule" "nodes_ingress_kubelet" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}