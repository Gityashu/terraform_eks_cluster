# Terraform EKS Cluster Module

This folder contains Terraform code to provision an Amazon EKS (Elastic Kubernetes Service) cluster on AWS.

## Features

- Provisions an EKS cluster
- Configures node groups
- Sets up networking (VPC, subnets, etc.)
- Supports custom configuration

## Usage

```hcl
module "eks" {
  source = "./terraform-eks"

  # Required variables
  cluster_name = "my-eks-cluster"
  region       = "us-west-2"
  node_count   = 2

  # ...other variables as needed
}
```

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS account and credentials with sufficient permissions

## How to Deploy

1. **Initialize Terraform**
   ```
   terraform init
   ```

2. **Review and Apply Plan**
   ```
   terraform plan
   terraform apply
   ```

3. **Access the Cluster**
   - Update your kubeconfig:
     ```
     aws eks --region <region> update-kubeconfig --name <cluster_name>
     ```

## Inputs

- `cluster_name` (string): Name of the EKS cluster
- `region` (string): AWS region
- `node_count` (number): Number of worker nodes

_See variables.tf for all configuration options._

## Outputs

- `cluster_id`: The ID of the EKS cluster
- `kubeconfig`: Kubeconfig file for accessing the cluster

## Clean Up

To destroy the resources:

```
terraform destroy
```

**Quick Start:**  
1. Edit variables in your module call.  
2. Run `terraform init && terraform apply`.  
3. Update kubeconfig and start using your EKS cluster!
