provider "aws" {
  region = "ap-northeast-2"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.prodxcloud-cluster-prod.endpoint
  cluster_ca_certificate = base64decode("${aws_eks_cluster.prodxcloud-cluster-prod.certificate_authority[0].data}")
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.prodxcloud-cluster-prod.name
}