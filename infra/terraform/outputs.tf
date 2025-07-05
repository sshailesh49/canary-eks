output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}

output "region" {
  value = var.region
}

output "grafana_url" {
  value       = helm_release.prometheus.status[0].load_balancer[0].ingress[0].hostname
  description = "Grafana LoadBalancer URL"
}




