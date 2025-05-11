# vpc_endpoints.tf 파일 생성
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.tenant_vpc.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private-ap-northeast-2a.id, aws_subnet.private-ap-northeast-2b.id]
  security_group_ids = [aws_security_group.eks_nodes_sg.id]
}

resource "aws_vpc_endpoint" "eks" {
  vpc_id            = aws_vpc.tenant_vpc.id
  service_name      = "com.amazonaws.ap-northeast-2.eks"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private-ap-northeast-2a.id, aws_subnet.private-ap-northeast-2b.id]
  security_group_ids = [aws_security_group.eks_nodes_sg.id]
}