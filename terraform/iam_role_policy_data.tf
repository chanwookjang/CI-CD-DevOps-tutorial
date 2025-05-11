# 1. EKS 클러스터 IAM 역할 생성
resource "aws_iam_role" "eks" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

# 2. EKS 클러스터 권한 정책 연결
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# 3. OIDC 공급자 설정 (IRSA용)
data "tls_certificate" "eks" {
  url = "${aws_eks_cluster.prodxcloud-cluster-prod.identity[0].oidc[0].issuer}"
  depends_on = [aws_eks_cluster.prodxcloud-cluster-prod]
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = "${aws_eks_cluster.prodxcloud-cluster-prod.identity[0].oidc[0].issuer}"
  depends_on      = [aws_eks_cluster.prodxcloud-cluster-prod]
}

# 4. 서비스 계정용 IAM 역할 (예시: S3 접근)
data "aws_iam_policy_document" "validate_oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:aws-validate"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "validate_oidc" {
  name               = "prod-test-oidc"
  assume_role_policy = data.aws_iam_policy_document.validate_oidc_assume_role_policy.json
}

resource "aws_iam_policy" "validate-policy" {
  name = "prod-validate-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
      Effect   = "Allow"
      Resource = "arn:aws:s3:::*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "validate_attach" {
  role       = aws_iam_role.validate_oidc.name
  policy_arn = aws_iam_policy.validate-policy.arn
}

###autoscaler

data "aws_iam_policy_document" "eks_cluster_autoscaler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_cluster_autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_autoscaler_assume_role_policy.json
  name               = var.eks-cluster-autoscaler
}

resource "aws_iam_policy" "eks_cluster_autoscaler" {
  name =  var.eks-cluster-autoscaler

  policy = jsonencode({
    Statement = [{
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_autoscaler_attach" {
  role       = aws_iam_role.eks_cluster_autoscaler.name
  policy_arn = aws_iam_policy.eks_cluster_autoscaler.arn
}

output "eks_cluster_autoscaler_arn" {
  value = aws_iam_role.eks_cluster_autoscaler.arn
}

##worker node role
# 1. EKS 노드용 IAM Role 생성
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
}

# 2. 신뢰 정책(Assume Role Policy) 데이터 소스
data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 3. EKS 노드에 필요한 AWS 관리형 정책 연결
resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

## EKS 노드용 AMI 데이터 소스
data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["602401143452"] # EKS 공식 AMI 소유자

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.32-v*"] # EKS 1.32 버전용 AMI
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# aws-auth-configmap.tf 생성
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = "${aws_iam_role.eks_node_role.arn}"
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
  }

  depends_on = [aws_eks_cluster.prodxcloud-cluster-prod]
}
