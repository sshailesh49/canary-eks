output "cluster_name" {
  value = aws_eks_cluster.my-eks-cluster.name
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc.arn
}
