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