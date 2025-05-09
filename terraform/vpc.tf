
## vpc
resource "aws_vpc" "tenant_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.tenant_vpc
    Owner = "prodxcloud"
  }

  lifecycle {
    prevent_destroy = false
  }
}


## subnets
resource "aws_subnet" "private-ap-northeast-2a" {
  vpc_id            = aws_vpc.tenant_vpc.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "ap-northeast-2a"

  tags = {
    "Name"                                          = "prodxcloud-tenant-private-ap-northeast-2a"
    "kubernetes.io/role/internal-elb"               = "1" ##내부 로드밸런싱
    "kubernetes.io/cluster/prodxcloud-cluster-prod" = "owned"
    "Service"                                       = "load-balancer"
    "ManagedBy"                                     = "Terraform"
    "CreatedBy"                                     = "DevOps Team"
    "Team"                                          = "Platform"
  }
  
}

resource "aws_subnet" "private-ap-northeast-2b" {
  vpc_id            = aws_vpc.tenant_vpc.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "ap-northeast-2b"

  tags = {
    "Name"                                          = "prodxcloud-tenant-private-ap-northeast-2b"
    "kubernetes.io/role/internal-elb"               = "1" ##프라이빗 서브넷이야 => 트래픽 from VPC 내부 서비스 → 내부 로드밸런서(너) → 백엔드 서버(EC2, 컨테이너 등)일 때 써줘
    "kubernetes.io/cluster/prodxcloud-cluster-prod" = "owned"
    "Service"                                       = "load-balancer"
    "ManagedBy"                                     = "Terraform"
    "CreatedBy"                                     = "DevOps Team"
    "Team"                                          = "Platform"

  }
}

resource "aws_subnet" "public-ap-northeast-2a" {
  vpc_id                  = aws_vpc.tenant_vpc.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true


  tags = {
    "Name"                                          = "prodxcloud-tenant-public-ap-northeast-2a"
    "kubernetes.io/role/elb"                        = "1" ##나 퍼블릭 서브넷이니까 외부서 오는 트래픽 로드밸런싱해줘
    "kubernetes.io/cluster/prodxcloud-cluster-prod" = "owned"
    "Service"                                       = "load-balancer"
    "ManagedBy"                                     = "Terraform"
    "CreatedBy"                                     = "DevOps Team"
    "Team"                                          = "Platform"
  }
}

resource "aws_subnet" "public-ap-northeast-2b" {
  vpc_id                  = aws_vpc.tenant_vpc.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                          = "prodxcloud-tenant-public-ap-northeast-2b"
    "kubernetes.io/role/elb"                        = "1" ##퍼블릭 로드밸런싱싱
    "kubernetes.io/cluster/prodxcloud-cluster-prod" = "owned"
    "Service"                                       = "load-balancer"
    "ManagedBy"                                     = "Terraform"
    "CreatedBy"                                     = "DevOps Team"
    "Team"                                          = "Platform"
  }
}


resource "aws_subnet" "public-ap-northeast-2c" {
  vpc_id                  = aws_vpc.tenant_vpc.id
  cidr_block              = "10.0.128.0/19"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                          = "prodxcloud-tenant-public-ap-northeast-2c"
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/prodxcloud-cluster-prod" = "owned"
    "Environment"                                   = "production"
    "Application"                                   = "prodxcloud"
    "Service"                                       = "load-balancer"
    "ManagedBy"                                     = "Terraform"
    "CreatedBy"                                     = "DevOps Team"
    "Team"                                          = "Platform"
  }
}