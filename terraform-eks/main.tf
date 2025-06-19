
# Copyright © 2025 Innovation AI Labs, Inc.

# All rights reserved.

# This software and associated documentation files (the "Software") are the exclusive property of Innovation AI Labs, LLC.Unauthorized copying, distribution, modification, or use of the Software, in whole or in part, is strictly prohibited without the prior written consent of Innovation AI Labs, LLC.# 1. VPC and Networking Setup for EKS

resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true # Allows EC2 instances to receive public DNS hostnames
  enable_dns_support   = true # Ensures DNS resolution within the VPC

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc"
  })
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-igw"
  })
}

# Data source to fetch available availability zones in the specified region
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "eks_public_subnets" {
  count                   = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = true # Automatically assign public IP addresses to instances launched in these subnets
  availability_zone       = data.aws_availability_zones.available.names[count.index] # Distribute across AZs

  tags = merge(var.tags, {
    Name                                = "${var.cluster_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # Tag for EKS auto-discovery of subnets
    "kubernetes.io/role/elb"            = "1"             # Tag for EKS to use these subnets for public load balancers
  })
}

resource "aws_subnet" "eks_private_subnets" {
  count             = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index] # Distribute across AZs

  tags = merge(var.tags, {
    Name                                = "${var.cluster_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # Tag for EKS auto-discovery of subnets
    "kubernetes.io/role/internal-elb"   = "1"             # Tag for EKS to use these subnets for internal load balancers
  })
}

resource "aws_route_table" "eks_public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"        # Default route to the internet
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-public-rt"
  })
}

resource "aws_route_table_association" "eks_public_rt_associations" {
  count          = length(aws_subnet.eks_public_subnets)
  subnet_id      = aws_subnet.eks_public_subnets[count.index].id
  route_table_id = aws_route_table.eks_public_rt.id
}

resource "aws_eip" "eks_nat_gateway_eip" {
  count      = length(aws_subnet.eks_public_subnets) # One EIP per public subnet for NAT Gateway
  depends_on = [aws_internet_gateway.eks_igw] # Ensure IGW is created before EIP is allocated for NAT

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-nat-gateway-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "eks_nat_gateway" {
  count         = length(aws_subnet.eks_public_subnets) # One NAT Gateway per public subnet
  allocation_id = aws_eip.eks_nat_gateway_eip[count.index].id
  subnet_id     = aws_subnet.eks_public_subnets[count.index].id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-nat-gateway-${count.index + 1}"
  })
}

resource "aws_route_table" "eks_private_rt" {
  count  = length(aws_subnet.eks_private_subnets) # One private route table per private subnet
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"        # Default route to NAT Gateway for internet access
    nat_gateway_id = aws_nat_gateway.eks_nat_gateway[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "eks_private_rt_associations" {
  count          = length(aws_subnet.eks_private_subnets)
  subnet_id      = aws_subnet.eks_private_subnets[count.index].id
  route_table_id = aws_route_table.eks_private_rt[count.index].id
}



# 2. IAM Roles for EKS Cluster and Nodes

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  # Trust policy for EKS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Attach AmazonEKSClusterPolicy to the cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Attach AmazonEKSServicePolicy to the cluster role (often included for EKS service features)
resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.cluster_name}-eks-node-group-role"

  # Trust policy for EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Attach AmazonEKSWorkerNodePolicy to the node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

# Attach AmazonEKS_CNI_Policy for networking (required by EKS nodes)
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

# Attach AmazonEC2ContainerRegistryReadOnly for pulling images from ECR (common)
resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}
# Add to node group role (Line 135-148)
resource "aws_iam_role_policy_attachment" "eks_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node_group_role.name
}



# 3. EKS Cluster Creation

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    # Combine public and private subnets for EKS cluster
    subnet_ids         = concat(aws_subnet.eks_public_subnets[*].id, aws_subnet.eks_private_subnets[*].id)
    security_group_ids = [aws_security_group.eks_cluster_sg.id] # Attach EKS cluster security group
  }

  # Enable desired control plane logging types
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = var.tags

  # Explicit dependencies to ensure resources are created in correct order
  /*depends_on = [
    aws_iam_role.eks_cluster_role,
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
    aws_internet_gateway.eks_igw,
    aws_nat_gateway.eks_nat_gateway, # Ensure NAT Gateway exists if private subnets are used
    aws_subnet.eks_public_subnets,
    aws_subnet.eks_private_subnets,
  ]*/
}


# 4. EKS Node Group and Launch Template


# Data source to fetch the latest EKS-optimized AMI for the specified Kubernetes version
data "aws_ami" "eks_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Local variable for the user data script to bootstrap EKS nodes
locals {
  bootstrap_script = <<-EOT
    #!/bin/bash
    # This script is executed on EC2 instances when they launch to join the EKS cluster.
    # It uses the EKS provided bootstrap.sh script.
    /etc/eks/bootstrap.sh ${var.cluster_name} --kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=OnDemand'
EOT
}

# Launch Template for EKS worker nodes
resource "aws_launch_template" "eks_it" {
  name_prefix   = "${var.cluster_name}-launch-template-"
  image_id      = data.aws_ami.eks_ami.id # Use the fetched EKS-optimized AMI
  instance_type = var.instance_type
  key_name      = var.key_name # Optional: Specify an EC2 Key Pair name here for SSH access to worker nodes
  vpc_security_group_ids = [aws_security_group.eks_node_sg.id] # Attach EKS node security group

  # EBS volume configuration for worker nodes
  block_device_mappings {
    device_name = "/dev/xvda" # Or /dev/sda1 for some AMIs
    ebs {
      volume_size = 20 # GiB, adjust based on your workload needs
      volume_type = "gp3" # General Purpose SSD
    }
  }

  user_data = base64encode(local.bootstrap_script) # Encode the bootstrap script

  tags = var.tags
}

# EKS Node Group managed by AWS
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.eks_private_subnets[*].id # Deploy nodes into private subnets

  # Scaling configuration for the Auto Scaling Group backing the node group
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  # Update configuration for rolling updates
  update_config {
    max_unavailable = 1 # Allow one node to be unavailable during updates
  }

  # Labels to apply to the Kubernetes nodes
  labels = {
    environment = "dev"
    project     = "eks-deployment"
  }

  # Use the defined launch template for node configuration
  launch_template {
    name    = aws_launch_template.eks_it.name
    version = "$Latest" # Always use the latest version of the launch template
  }

  tags = var.tags

  # Explicit dependencies to ensure roles and cluster are ready before creating node group
  depends_on = [
    aws_iam_role.eks_node_group_role,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_readonly,
    aws_eks_cluster.eks_cluster,
  ]
}

# 5. Security Groups for EKS Cluster and Nodes


resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane communication"
  vpc_id      = aws_vpc.eks_vpc.id

  # Ingress rule to allow access to the EKS control plane (port 443) from public subnets
  # This is for internal EKS operations and might be restricted further in production.
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #security_groups = [aws_security_group.eks_node_sg.id] # Allow access from EKS worker nodes
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block] # Allow access from public subnets for control plane
    description = "Allow EKS control plane access from public subnets"
  }

  # Egress rule to allow all outbound traffic from the control plane
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = var.tags
}

resource "aws_security_group" "eks_node_sg" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.eks_vpc.id

  # Ingress from EKS control plane (managed by AWS) to Kubelet port
  ingress {
    from_port   = 10250 # Kubelet port
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block] # Allow from the entire VPC CIDR block
    #security_groups = [aws_security_group.eks_cluster_sg.id] # Allow from EKS control plane SG
    description = "Allow kubelet access from EKS control plane"
  }
  # Ingress for cluster communication on port 443 (for API server)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ aws_vpc.eks_vpc.cidr_block] # Allow from the entire VPC CIDR block]
    #security_groups = [aws_security_group.eks_cluster_sg.id] # Allow from EKS control plane SG
    description = "Allow API server access from EKS control plane"
  }
  
  # Ingress for Load Balancer health checks
  ingress {
    from_port   = 80 # Or 443 if using HTTPS for application
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id] # Allow from EKS control plane SG
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block] # Broad access for health checks, refine as needed for specific ALB/NLB source IPs
    description = "Allow HTTP for Load Balancer health checks (adjust CIDR for production)"
  }
  # Ingress for inter-node communication (allowing all traffic within the SG)
  ingress {

    from_port       = 0
    to_port         = 0
    protocol        = "-1" # All protocols
    self            = true # Allow traffic from other instances in this security group
    description     = "Inter-node communication"
  }
  


  # Egress rule to allow all outbound traffic from worker nodes
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = var.tags
}



# 6. Kubernetes Provider Configuration and aws-auth ConfigMap
# Data source to get EKS cluster authentication token
#data "aws_eks_cluster" "cluster" {
#  name = "my-eks-cluster"
#}

data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = aws_eks_cluster.eks_cluster.name
}

# Null resource to introduce a delay for EKS API endpoint to stabilize.
# This helps resolve "tls: failed to verify certificate" errors, which
# commonly occur due to race conditions when the EKS control plane is new.
resource "null_resource" "wait_for_eks_endpoint" {
  # This resource depends on the EKS cluster being fully provisioned.
  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_eks_node_group.eks_node_group # Also wait for node group for better stability
  ]

  # Execute a local command (sleep) to pause Terraform for a duration.
  # Adjust the sleep time as needed (e.g., 60-120 seconds for production).
  provisioner "local-exec" {
    command = "echo 'Waiting 90 seconds for EKS control plane to stabilize...'; sleep 90"
    # For Windows systems, use: command = "timeout /t 90 /nobreak"
  }

  triggers = {
    # This ensures the null_resource runs every time the EKS cluster ID changes
    cluster_id = aws_eks_cluster.eks_cluster.id
  }
}

# Kubernetes ConfigMap for aws-auth, necessary for worker nodes to join the cluster
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system" # Must be in kube-system namespace
  }

  data = {
    # Map the EKS node group IAM role to Kubernetes groups
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node_group_role.arn
        username = "system:node:{{EC2PrivateDNSName}}" # EKS internal user for nodes
        groups   = ["system:bootstrappers", "system:nodes"] # Required groups for worker nodes
      }
    ])
  }

  # Explicit dependencies to ensure the cluster, node group, and the
  # stability wait are complete before configuring aws-auth.
  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_eks_node_group.eks_node_group,
    null_resource.wait_for_eks_endpoint # Crucial for solving TLS errors
  ]
}

# Optional: Data source to get current AWS account ID for mapUsers/mapAccounts
data "aws_caller_identity" "current" {}
