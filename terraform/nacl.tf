# NACL 생성 및 규칙 정의
resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.tenant_vpc.id
  subnet_ids = [ 
    aws_subnet.private-ap-northeast-2a.id,
    aws_subnet.private-ap-northeast-2b.id 
  ]

  # 아웃바운드: HTTPS(443) 허용
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # 아웃바운드: Ephemeral 포트 허용 (노드 ↔ EKS API 통신 필수)
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "private-subnet-nacl"
  }

  # 인바운드: 80, 443, 1024-65535 허용
ingress {
  protocol   = "tcp"
  rule_no    = 100
  action     = "allow"
  cidr_block = "0.0.0.0/0"
  from_port  = 80
  to_port    = 80
}
ingress {
  protocol   = "tcp"
  rule_no    = 110
  action     = "allow"
  cidr_block = "10.0.0.0/16"  # VPC CIDR로 변경
  from_port  = 443
  to_port    = 443
}
ingress {
  protocol   = "tcp"
  rule_no    = 120
  action     = "allow"
  cidr_block = "0.0.0.0/0"
  from_port  = 1024
  to_port    = 65535
}
}
