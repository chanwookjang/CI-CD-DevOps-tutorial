resource "aws_security_group" "eks_nodes" {
  name        = "eks-node-sg"
  description = "EKS worker node security group"
  vpc_id      = aws_vpc.tenant_vpc.id

  # 인바운드: 노드 간 모든 트래픽 허용 (SG 자기 자신)
  ingress {
    description      = "Allow node-to-node communication"
    from_port        = 0
    to_port          = 65535
    protocol         = "-1"
    self             = true
  }

  #필요시 외부에서 Load Balancer로 접근 허용 (예: 80, 443)
  ingress {
    description = "Allow HTTP/HTTPS from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드: 모든 트래픽 허용 (기본값)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-node-sg"
  }
}

# NACL 리소스 정의
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.tenant_vpc.id
  subnet_ids = [
    aws_subnet.private-ap-northeast-2a.id
  ]
  tags = {
    Name = "private-nacl"
  }
}

# 인바운드 규칙 (예: 443 허용)
resource "aws_network_acl_rule" "private_ingress_443" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# 아웃바운드 규칙 (예: 전체 허용)
resource "aws_network_acl_rule" "private_egress_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}


### EKS 클러스터와 노드 간의 보안 그룹 설정
resource "aws_security_group" "eks_cluster_sg" {
  name   = "eks-cluster"
  vpc_id = aws_vpc.tenant_vpc.id
  # 인라인 ingress/egress 규칙 없이 정의
}

resource "aws_security_group" "eks_nodes_sg" {
  name   = "eks-nodes"
  vpc_id = aws_vpc.tenant_vpc.id
  # 인라인 ingress/egress 규칙 없이 정의
}

# eks_nodes SG에 eks_cluster SG에서 오는 443 포트 허용
resource "aws_security_group_rule" "nodes_from_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}

# eks_cluster SG에 eks_nodes SG에서 오는 443 포트 허용 (필요하다면)
resource "aws_security_group_rule" "cluster_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
}