variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "my-eks-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for node group"
  type        = string
  default     = "t2.medium"
}

variable "desired_size" {
  default     = 2
}

variable "min_size" {
  default     = 2
}

variable "max_size" {
  default     = 2
}

variable "alb_controller_version" {
  default     = "1.7.1"
}

variable "tags" {
  type        = map(string)
  default     = {
    Environment = "dev"
    Terraform   = "true"
  }
}

