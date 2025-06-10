# outputs.tf

output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  description = "The API endpoint for the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_arn" {
  description = "The ARN (Amazon Resource Name) of the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.arn
}

output "eks_cluster_version" {
  description = "The Kubernetes version of the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.version
}

output "vpc_id" {
  description = "The ID of the VPC created for EKS."
  value       = aws_vpc.eks_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs where public load balancers will be deployed."
  value       = aws_subnet.eks_public_subnets[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs where worker nodes are deployed."
  value       = aws_subnet.eks_private_subnets[*].id
}

output "eks_node_group_arn" {
  description = "The ARN of the EKS Managed Node Group."
  value       = aws_eks_node_group.eks_node_group.arn
}

output "configure_kubectl" {
  description = "Command to configure kubectl to connect to the EKS cluster. Run this command after 'terraform apply'."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.eks_cluster.name}"
}