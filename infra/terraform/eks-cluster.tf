resource "aws_eks_cluster" "my-eks-cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# Enable OIDC
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.my-eks-cluster.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.my-eks-cluster.name
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.my-eks-cluster.identity[0].oidc[0].issuer
}

data "tls_certificate" "oidc_cert" {
  url = aws_eks_cluster.my-eks-cluster.identity[0].oidc[0].issuer
}
