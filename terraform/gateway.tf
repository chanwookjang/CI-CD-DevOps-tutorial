resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tenant_vpc.id

  tags = {
    Name = "prodxcloud-tenant-eks-internet-gateway"
  }
  depends_on = [ aws_vpc.tenant_vpc ]
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "prodxcloud-tenant-nat-eip"
  }

  depends_on = [ aws_vpc.tenant_vpc ]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-ap-northeast-2a.id

  tags = {
    Name = "prodxcloud-tenant-nat-gateway"
  }
  
  depends_on = [aws_internet_gateway.igw]
}


# 프라이빗 라우팅 테이블 생성 및 NAT Gateway로 라우팅 추가
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.tenant_vpc.id

# 이렇게 하면 프라이빗 서브넷에서 인터넷으로 나가는 트래픽을 NAT Gateway로 라우팅할 수 있어 노드가 클러스터에 접근할 수 있어
  route { 
    cidr_block     = "0.0.0.0/0" ##destination
    nat_gateway_id = aws_nat_gateway.nat.id ##target
  }

  tags = {
    Name = "private-route-table"
  }
}

# 프라이빗 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private-ap-northeast-2a.id ##프라이빗 서브넷a 지정!!
  route_table_id = aws_route_table.private.id
} 

