# variables.tf

variable "aws_region" {
  description = "The AWS region where the EKS cluster will be created."
  type        = string
  default     = "ap-south-1" # Defaulting to Mumbai region
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.28" # Specify your desired Kubernetes version (e.g., "1.29", "1.30")
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC that will host the EKS cluster."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks for public subnets (for external facing services/load balancers)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # Example: two public subnets for high availability
}

variable "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks for private subnets (where worker nodes will reside)."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"] # Example: two private subnets
}

variable "instance_type" {
  description = "EC2 instance type for EKS worker nodes."
  type        = string
  default     = "t3.medium" # A general-purpose instance type, consider t3.large for more demanding workloads
}

variable "desired_size" {
  description = "Desired number of worker nodes in the EKS node group."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes allowed in the EKS node group."
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes allowed in the EKS node group."
  type        = number
  default     = 1
}

variable "tags" {
  description = "A map of tags to apply to all created AWS resources for identification and cost allocation."
  type        = map(string)
  default = {
    Project     = "EKS-Terraform-Deployment"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}