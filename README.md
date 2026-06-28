# Monolithic Project - DevOps Infrastructure as Code

A comprehensive Infrastructure as Code (IaC) project that automates the deployment and management of a scalable web server infrastructure on AWS using Terraform and Ansible, with CI/CD orchestration via Jenkins.

## Overview

This project demonstrates enterprise-grade DevOps practices by automating the entire infrastructure provisioning and application deployment lifecycle. It combines Infrastructure as Code (Terraform), Configuration Management (Ansible), and Continuous Integration/Continuous Deployment (Jenkins) to create a reproducible, scalable, and maintainable infrastructure stack.

## Features and Capabilities

- **Infrastructure Automation**: Complete AWS infrastructure provisioning using Terraform
- **Auto-Scaling**: Automatic scaling of EC2 instances based on demand (min: 1, max: 3, desired: 2)
- **Load Balancing**: Application Load Balancer (ELB) for distributing traffic across instances
- **State Management**: Remote state storage in S3 with versioning enabled
- **Security**: Dedicated security groups with controlled ingress/egress rules
- **Configuration Management**: Ansible-based automated deployment and application setup
- **CI/CD Pipeline**: Jenkins pipeline for automated testing, planning, and deployment
- **Dynamic Inventory**: Ansible dynamic inventory for AWS EC2 instance discovery

## Project Architecture

```
Monolithic-Project/
├── README.md                    # Project documentation
├── provider.tf                  # AWS provider configuration
├── backend.tf                   # Remote state configuration (S3)
├── main.tf                      # EC2 Launch Template, Load Balancer, Auto Scaling Group
├── s3.tf                        # S3 bucket for state management
├── security.tf                  # AWS Security Groups
├── Jenkinsfile                  # CI/CD pipeline configuration
└── ansible/
    ├── deployment.yml           # Ansible playbook for application deployment
    └── inventory/
        └── aws_ec2.yml          # Dynamic inventory plugin configuration
```

### Architecture Flow

```
GitHub Repository
    ↓
Jenkins Pipeline
    ├─ Code: Clone repository
    ├─ Init: Terraform init
    ├─ Plan: Terraform plan
    ├─ Action: Terraform apply/destroy
    └─ Deploy: Ansible playbook execution
    ↓
AWS Infrastructure
    ├─ EC2 Auto Scaling Group (2 instances)
    ├─ Elastic Load Balancer (ELB)
    ├─ Security Groups (SSH, HTTP, HTTPS)
    └─ S3 Bucket (State management)
```

## Prerequisites and Dependencies

### System Requirements

- **Operating System**: Linux (Ubuntu, Amazon Linux, or CentOS)
- **Disk Space**: Minimum 30GB EBS volume recommended
- **Network**: Internet connectivity to AWS and GitHub

### Software Dependencies

- **Terraform**: v1.x or higher
- **Ansible**: v2.9 or higher
- **Git**: Latest stable version
- **Python**: 3.6 or higher
- **pip**: Python package manager
- **Jenkins**: v2.x or higher (for CI/CD)
- **AWS CLI**: v2 for AWS operations

### AWS Requirements

- Active AWS account with appropriate IAM permissions
- EC2 key pair for SSH access (e.g., `Docker-RSA`)
- S3 bucket for Terraform state (e.g., `kailash.project.monobucket`)
- Access to ap-south-1 region (Mumbai) or modify provider configuration

## Installation Instructions

### 1. Set Up Jenkins Server

Launch and configure an EC2 instance as the Jenkins master server:

```bash
# Update system packages
sudo yum update -y
sudo yum upgrade -y

# Install Java (required for Jenkins)
sudo yum install java-11-openjdk java-11-openjdk-devel -y

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins
```

### 2. Install Required Tools

```bash
# Install Git
sudo yum install git -y

# Install Python and pip
sudo yum install python3 python3-pip -y

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# Install Ansible
sudo pip3 install ansible
sudo pip3 install boto3 botocore  # Required for AWS dynamic inventory
ansible --version

# Install AWS CLI
sudo pip3 install awscli
aws --version
```

### 3. Configure Jenkins Plugins

Access Jenkins web UI and install the following plugins:

1. Navigate to **Manage Jenkins** → **Manage Plugins** → **Available**
2. Search for and install:
   - **Pipeline Stage View** - For visualizing pipeline stages
   - **GitHub Integration** - For GitHub webhooks
   - **AWS Steps** - For AWS operations
   - **Ansible Plugin** - For Ansible integration

### 4. Clone the Repository

```bash
cd /opt
git clone https://github.com/kailashTuta/Monolithic-Project.git
cd Monolithic-Project
```

### 5. Configure AWS Credentials

Set up AWS credentials for Terraform and Ansible:

```bash
# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID, Secret Access Key, default region (ap-south-1)

# Verify configuration
aws s3 ls
```

## Configuration Details

### Terraform Configuration Files

#### **provider.tf** - AWS Provider Configuration
Specifies the AWS provider and region:
```hcl
provider "aws" {
  region = "ap-south-1"
}
```

#### **backend.tf** - Remote State Management
Configures S3 as the backend for storing Terraform state:
```hcl
terraform {
    backend "s3" {
        region = "ap-south-1"
        bucket = "kailash.project.monobucket"
        key = "prod/terraform.tfstate"
    }
}
```

**Key Parameters:**
- **bucket**: S3 bucket name for state storage (pre-created)
- **key**: Path within S3 bucket for state file
- **region**: AWS region for S3 access

#### **s3.tf** - S3 Bucket for State Management
- Bucket name: `kailash.project.monobucket`
- Ownership controls: BucketOwnerPreferred
- ACL: Private
- Versioning: Enabled (for state recovery)

#### **security.tf** - Security Group Configuration
Defines ingress/egress rules:
- **SSH (22)**: Accessible from anywhere (0.0.0.0/0)
- **HTTP (80)**: Accessible from anywhere (0.0.0.0/0)
- **HTTPS (443)**: Accessible from anywhere (0.0.0.0/0)
- **Egress**: All traffic allowed (0.0.0.0/0)

#### **main.tf** - Core Infrastructure
Defines three main resources:

1. **Launch Template** (`aws_launch_template.web_server_as`):
   - AMI: `ami-0bc7aabcf58d1e02a` (Amazon Linux 2)
   - Instance Type: `t3.micro`
   - Key Name: `Docker-RSA` (for SSH access)
   - Security Group: References web_server security group

2. **Elastic Load Balancer** (`aws_elb.web_server_lb`):
   - Listener: HTTP on port 80
   - Subnets: ap-south-1a, ap-south-1b
   - Name: `web-server-lb`

3. **Auto Scaling Group** (`aws_autoscaling_group.web_server_asg`):
   - Min Size: 1 instance
   - Max Size: 3 instances
   - Desired Capacity: 2 instances
   - Health Check: EC2 based
   - Availability Zones: ap-south-1a, ap-south-1b

### Ansible Configuration

#### **ansible/deployment.yml** - Deployment Playbook
Configures web servers with the following tasks:
- Install Apache HTTP Server (httpd)
- Start httpd service
- Install Git
- Clone source code from GitHub: `https://github.com/devops0014/staticsite-docker.git`

#### **Dynamic Inventory Setup**

Create `/opt/ansible/inventory/aws_ec2.yml`:
```yaml
---
plugin: aws_ec2
regions:
  - ap-south-1
filters:
  tag:aws:ec2launchtemplate:id: <launch-template-id>
```

Update `/etc/ansible/ansible.cfg`:
```ini
[defaults]
inventory = /opt/ansible/inventory/aws_ec2.yml
host_key_checking = False
enable_plugins = aws_ec2
```

### Jenkins Pipeline Configuration

The pipeline includes five stages:

1. **Code**: Clone the repository from GitHub
2. **Init**: Initialize Terraform working directory
3. **Plan**: Generate infrastructure execution plan
4. **Action**: Apply or destroy infrastructure (parameterized)
5. **Deploy**: Execute Ansible playbook for application deployment

## Usage Instructions and Examples

### 1. Terraform Workflow

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan infrastructure changes
terraform plan

# Apply configuration (create infrastructure)
terraform apply --auto-approve

# View current state
terraform state list

# Destroy infrastructure when done
terraform destroy --auto-approve
```

### 2. Ansible Deployment

```bash
# Test dynamic inventory
ansible-inventory -i /opt/ansible/inventory/aws_ec2.yml --list

# Run deployment playbook
ansible-playbook -i /opt/ansible/inventory/aws_ec2.yml ansible/deployment.yml

# Check connectivity to hosts
ansible all -i /opt/ansible/inventory/aws_ec2.yml -m ping
```

### 3. Jenkins Job Setup

1. Create a new **Pipeline** job in Jenkins
2. Configure the pipeline script path: `Jenkinsfile` from repository
3. Add a string parameter `action` (default: `plan`, or `apply`/`destroy`)
4. Trigger manually or configure GitHub webhook for automated triggers

### 4. SSH into Deployed Instances

```bash
# Get instance IP from AWS Console or Terraform output
ssh -i /path/to/Docker-RSA.pem ec2-user@<instance-ip>

# Verify httpd is running
curl http://<instance-ip>
```

## Available Scripts and Commands

### Terraform Commands

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize Terraform working directory |
| `terraform validate` | Validate configuration files |
| `terraform plan` | Generate execution plan |
| `terraform apply` | Create/update infrastructure |
| `terraform destroy` | Remove infrastructure |
| `terraform fmt` | Format configuration files |
| `terraform state list` | List resources in state |

### Ansible Commands

| Command | Description |
|---------|-------------|
| `ansible-playbook` | Execute playbook |
| `ansible-inventory` | Display inventory |
| `ansible all -m ping` | Test connectivity |
| `ansible-doc -l` | List available modules |

### System Commands

```bash
# Check Terraform version
terraform --version

# Check Ansible version
ansible --version

# Check AWS CLI configuration
aws sts get-caller-identity

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log
```

## Getting Started - Quick Start Guide

Follow these steps to get the project up and running:

### Step 1: Clone the Repository

```bash
git clone https://github.com/kailashTuta/Monolithic-Project.git
cd Monolithic-Project
```

### Step 2: Install Required Dependencies

```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install Ansible
sudo apt-get install python3-pip
sudo pip3 install ansible boto3

# Install AWS CLI
sudo apt-get install awscli

# Install Git
sudo apt-get install git
```

### Step 3: Configure AWS Credentials

```bash
# Set up AWS credentials
aws configure

# Verify access
aws ec2 describe-regions
```

### Step 4: Set Up S3 Backend

Ensure the S3 bucket exists before initializing Terraform:

```bash
# Check if bucket exists
aws s3 ls s3://kailash.project.monobucket/

# If not, create it (optional)
aws s3 mb s3://kailash.project.monobucket/ --region ap-south-1
```

### Step 5: Initialize Terraform

```bash
cd /opt/Monolithic-Project
terraform init
```

### Step 6: Configure Ansible Dynamic Inventory

```bash
# Create directory structure
mkdir -p /opt/ansible/inventory

# Copy your EC2 key
sudo cp /path/to/Docker-RSA.pem /etc/ansible/Docker-RSA.pem
sudo chmod 600 /etc/ansible/Docker-RSA.pem

# Create aws_ec2.yml inventory
cat > /opt/ansible/inventory/aws_ec2.yml << 'EOF'
---
plugin: aws_ec2
regions:
  - ap-south-1
filters:
  tag:aws:ec2launchtemplate:id: lt-xxxxxxxxxxxxxxx
EOF

# Update /etc/ansible/ansible.cfg
sudo tee -a /etc/ansible/ansible.cfg > /dev/null << 'EOF'
inventory = /opt/ansible/inventory/aws_ec2.yml
host_key_checking = False
enable_plugins = aws_ec2
EOF
```

### Step 7: Plan Infrastructure Deployment

```bash
terraform plan
```

### Step 8: Build/Deploy Infrastructure

```bash
# Apply Terraform configuration
terraform apply --auto-approve
```

### Step 9: Verify Setup with a Sample Command

```bash
# Wait for instances to be ready (2-3 minutes)
# Check instances are running
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Test deployment via Ansible
ansible-playbook -i /opt/ansible/inventory/aws_ec2.yml ansible/deployment.yml

# Verify web servers are responding
# Get load balancer DNS name from Terraform output or AWS Console
curl http://<load-balancer-dns>/
```

### Step 10: Run the Application

```bash
# Get Load Balancer DNS
aws elb describe-load-balancers --load-balancer-names web-server-lb --query 'LoadBalancerDescriptions[0].DNSName' --output text

# Access the application
curl http://<load-balancer-dns>/
```

## Technologies and Frameworks Used

- **Infrastructure as Code (IaC)**:
  - **Terraform**: v1.x - Infrastructure provisioning
  
- **Cloud Provider**:
  - **AWS**: EC2, ELB, Auto Scaling, S3, Security Groups
  
- **Configuration Management**:
  - **Ansible**: v2.9+ - Server configuration and deployment
  
- **CI/CD**:
  - **Jenkins**: v2.x - Pipeline orchestration
  
- **Source Control**:
  - **Git/GitHub**: Version control and repository
  
- **Languages & Tools**:
  - **HCL (HashiCorp Configuration Language)**: Terraform code
  - **YAML**: Ansible playbooks and inventory
  - **Python**: Ansible plugins and AWS integration
  - **Bash**: Shell scripts for setup and automation
  
- **AWS Services**:
  - EC2 (Elastic Compute Cloud)
  - ELB (Elastic Load Balancer)
  - Auto Scaling Groups
  - S3 (Simple Storage Service)
  - Security Groups
  - IAM (Identity and Access Management)

## Environment Variables

No explicit environment variables are required, but ensure the following are configured:

- **AWS_PROFILE** or **AWS credentials** in `~/.aws/credentials`
- **AWS_REGION**: Set to `ap-south-1` or update in `provider.tf`
- **Ansible settings** in `/etc/ansible/ansible.cfg`

## Troubleshooting Guide

### Terraform Issues

**Error: "Error acquiring the state lock"**
- Solution: Run `terraform force-unlock <LOCK_ID>` or delete the lock in S3

**Error: "Failed to download module"**
- Solution: Check internet connectivity and module sources in configuration

### Ansible Issues

**Error: "Host unreachable"**
- Verify security group allows SSH (port 22)
- Check EC2 key permissions: `chmod 600 Docker-RSA.pem`
- Ensure instances are fully launched before running playbook

**Error: "Permission denied (publickey)"**
- Verify `ansible_ssh_private_key_file` path in `deployment.yml`
- Check key file permissions and ownership

### AWS Issues

**Error: "InvalidParameterValue" for AMI**
- Verify AMI ID exists in your region: `aws ec2 describe-images --image-ids ami-0bc7aabcf58d1e02a --region ap-south-1`
- Update AMI ID in `main.tf` if necessary

**Error: "AuthFailure" with AWS CLI**
- Run `aws sts get-caller-identity` to verify credentials
- Check IAM permissions for EC2, ELB, S3, Auto Scaling

## Contributing Guidelines

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Standards

- Use consistent indentation (2 spaces for HCL, YAML)
- Add descriptive comments for complex logic
- Follow Terraform naming conventions
- Test changes in a non-production environment first
- Update README.md if making configuration changes

## License Information

This project is a fork of [devops0014/devops18](https://github.com/devops0014/devops18).

**License**: Not specified. Check the original repository for license details.

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)

## Support and Contact

For issues, questions, or suggestions:
- Open an issue on the [GitHub repository](https://github.com/kailashTuta/Monolithic-Project)
- Review the troubleshooting section above

---

**Last Updated**: 2026-06-28
**Repository**: [kailashTuta/Monolithic-Project](https://github.com/kailashTuta/Monolithic-Project)
