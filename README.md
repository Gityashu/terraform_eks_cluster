# Terraform EKS Cluster

Easily create and manage an AWS EKS (Elastic Kubernetes Service) cluster using Terraform.

## Features

- Automated EKS cluster setup
- Creates and manages necessary AWS resources (VPC, subnets, node groups)
- Simple configuration using variables

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Gityashu/terraform_eks_cluster.git
   cd terraform_eks_cluster
   ```

2. **Configure AWS credentials** (use `aws configure` or set environment variables).

3. **Edit variables** (optional):  
   Change values in `variables.tf` or create a `terraform.tfvars` file.

4. **Deploy the cluster:**
   ```bash
   terraform init
   terraform apply
   ```

5. **Access your cluster:**
   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster_name>
   ```

## Requirements

- Terraform
- AWS CLI
- AWS account with permissions

## Clean Up

To remove all resources:
```bash
terraform destroy
```

## License

MIT
