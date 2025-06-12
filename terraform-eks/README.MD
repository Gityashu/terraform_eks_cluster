# Your EKS Cluster, Built in Minutes with Terraform!
 Overview
This project uses Terraform to quickly set up a complete Amazon EKS (Kubernetes) cluster on AWS. It automates all the hard parts like setting up networks and permissions, giving you a ready-to-use cluster for your applications.

 What You'll Get (Key Features)
 Complete Network Setup: A secure network with public and private areas.

🛡 Secure Permissions: Correct AWS IAM roles for EKS and your worker machines.

 Managed Kubernetes: An EKS cluster that AWS handles for you.
 Auto-Scaling Worker Nodes: EC2 machines that automatically join your cluster and scale as needed.

 Basic Security: Firewall rules for cluster components.

 Auto Node Connect: Worker nodes automatically connect to your cluster securely.



🛠️ Prerequisites
Before you embark on your EKS journey, ensure you have these tools ready on your local machine:

Terraform CLI (v1.0.0+): Your infrastructure-as-code orchestrator.

Installation Guide

AWS CLI v2: The command-line interface for interacting with AWS services.

Installation Guide

Crucial: Configure your AWS credentials using aws configure. Ensure your IAM user has permissions to create VPCs, EKS clusters, IAM roles, and more.

kubectl: The command-line tool for running commands against Kubernetes clusters.

⚙️ Configuration (Make it Yours!)
All the magic happens in variables.tf! Open it up and tweak the values to fit your needs:

aws_region: Choose your preferred AWS region (e.g., "ap-south-1" for Mumbai).

cluster_name: Give your EKS cluster a memorable name.

cluster_version: Pick your desired Kubernetes version (e.g., "1.28").

vpc_cidr_block: Define the network range for your VPC.

public_subnet_cidr_blocks & private_subnet_cidr_blocks: Customize your subnet ranges.

instance_type: Select the EC2 instance type for your worker nodes (e.g., "t3.medium").

desired_size, max_size, min_size: Control the scaling behavior of your node group.

tags: Add your organization's tags for easy resource identification and cost management.

🚀 Let's Deploy! (Quick Start Guide)
Follow these steps to bring your EKS cluster to life:

Navigate to your project:

cd eks-cluster-terraform


Initialize Terraform:
This prepares your working directory and downloads necessary plugins.

terraform init


Plan your infrastructure:
See exactly what Terraform will create, modify, or destroy. This is your safety net!

terraform plan


Review the output carefully to ensure it aligns with your expectations.

Apply the magic:
Confirm the plan by typing yes when prompted. Go grab a coffee ☕, this step can take 15-25 minutes as AWS provisions the EKS control plane and nodes.

terraform apply


🔗 Accessing Your Brand New Cluster
Once terraform apply finishes its epic journey, you're ready to connect!

Configure kubectl:
Terraform provides a convenient command in its outputs. Copy and paste it directly into your terminal:

# This command will be shown in your `terraform apply` output:
# Example: aws eks update-kubeconfig --region ap-south-1 --name my-eks-cluster
# Run the exact command outputted by Terraform.


This command updates your local kubeconfig file (usually ~/.kube/config), allowing kubectl to talk to your new EKS cluster.

Verify access:
Let's see your cluster in action!

kubectl get svc
kubectl get nodes


You should see the default Kubernetes services and your new worker nodes (they might take a few more minutes to show as Ready). 🎉

🗑️ Cleaning Up (Don't Forget!)
When you're done experimenting or if you need to tear down your environment, it's easy:

Destroy everything:

terraform destroy


Type yes when prompted. This will delete all AWS resources created by this Terraform configuration, preventing unnecessary charges.

⚠️ Important Considerations
Cost Management: EKS incurs costs! The control plane, EC2 instances, NAT Gateways, and Elastic IPs all contribute. Always terraform destroy when your cluster is not in use.

IAM Permissions: The AWS credentials used by Terraform must have sufficient permissions to create all specified AWS resources.

Security Best Practices: The provided security groups are a good starting point. For production workloads, consider hardening them further based on your application's specific port requirements.

Availability Zones: This configuration distributes resources across available AZs. Ensure your chosen region has at least two for high availability.

aws-auth: By default, only the node group role can join the cluster. If you need specific IAM users or roles to administer the cluster via kubectl, you'll need to manually extend the mapUsers section in main.tf's kubernetes_config_map.aws_auth resource.

➡️ What's Next? (Beyond the Basics)
Your EKS cluster is a powerful canvas! Here are some ideas for what to do next:

Deploy EKS Add-ons: Integrate essential tools like the AWS Load Balancer Controller, Cluster Autoscaler, or ExternalDNS using Terraform's Helm provider.

CI/CD Pipelines: Hook this Terraform setup into your favorite CI/CD system (e.g., GitHub Actions, GitLab CI/CD, Jenkins) for automated deployments.

Application Deployment: Start deploying your containerized applications onto your new Kubernetes cluster!

Monitoring & Logging: Set up robust monitoring with Prometheus/Grafana or centralize logs with Fluent Bit to CloudWatch.

Secrets Management: Integrate with AWS Secrets Manager for secure handling of sensitive data.

Multi-Node Groups: If your workloads have different requirements, create multiple node groups with varying instance types.
