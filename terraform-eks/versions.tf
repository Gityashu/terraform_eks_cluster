# versions.tf

terraform {
  required_version = ">= 1.0.0" # Specify your desired minimum Terraform version

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a compatible AWS provider version
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23" # Use a compatible Kubernetes provider version
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0" # Used implicitly by Kubernetes provider for TLS if needed, good to include
    }
  }
}

# Configure the AWS provider with the specified region
provider "aws" {
  region = var.aws_region
}

# Configure the Kubernetes provider
# This configuration is dynamic. The `host`, `cluster_ca_certificate`,
# and `token` are retrieved from the EKS cluster outputs once it's created.
provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  #cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
}