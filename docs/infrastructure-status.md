# Runic Infrastructure Status

## 📋 Overview

This document tracks the current development infrastructure setup and outlines the planned production architecture for the Runic project.

---

## ✅ Current Development Setup

### 🏗️ **VPC & Networking**

- **VPC**: Custom VPC (`runic-dev-ec2-vpc`) with CIDR `10.0.0.0/16`
- **Region**: `us-west-2`
- **Availability Zone**: `us-west-2a`

### 🌐 **Subnets**

- **Public Subnet**: `10.0.1.0/24` (`runic-dev-ec2-public-subnet`)
  - Used for EC2 instance with direct internet access
  - Enables package updates and software installations
  - `map_public_ip_on_launch = true`

### 🖥️ **EC2 Instance**

- **Instance Type**: `t3.medium` (4GB RAM, 2 vCPUs)
- **AMI**: `ami-0ec1bf4a8f92e7bd1`
- **Network**: Public subnet with direct public IP
- **SSH Key**: `shaniac-ec2-key`
- **Purpose**: Development and testing environment

### 🐳 **Kubernetes Cluster**

- **Version**: 1.29.7 (stable release)
- **Container Runtime**: containerd with systemd cgroup driver
- **CNI**: Flannel (10.244.0.0/16 pod network)
- **Type**: Single-node cluster (control plane + worker)
- **Bootstrap**: Automated installation via user_data script
- **Test Deployment**: nginx with NodePort service

### 🔒 **Security Configuration**

- **Security Group**: `runic-ec2-sg-*`
  - **Inbound Rules**:
    - SSH (22): Open from anywhere (configurable to specific IPs)
    - HTTP (80): For package updates
    - HTTPS (443): For secure package updates
    - Kubernetes API (6443): For kubectl access
    - NodePort Services (30000-32767): For application access
  - **Outbound Rules**: All traffic allowed (0.0.0.0/0)

### 💰 **Cost Optimization**

- **No NAT Gateway**: Saves ~$32/month during testing
- **No Bastion Host**: Direct SSH access simplifies development
- **No Load Balancer**: Not needed for current development phase
- **Single EC2 Instance**: Optimized for development workloads
- **Estimated Cost**: ~$2/month with 2 hours/day, 3 days/week usage

---

## ⚡ Planned Production Architecture

### 🏗️ **VPC & Networking**

- **VPC**: Multi-AZ setup across `us-west-2a`, `us-west-2b`, `us-west-2c`
- **High Availability**: Redundant resources across availability zones

### 🌐 **Subnets (Multi-AZ)**

- **Public Subnets**:

  - `us-west-2a`: `10.0.1.0/24` - Load Balancers, Bastion Host
  - `us-west-2b`: `10.0.2.0/24` - Load Balancers, Bastion Host
  - `us-west-2c`: `10.0.3.0/24` - Load Balancers, Bastion Host

- **Private Subnets**:
  - `us-west-2a`: `10.0.10.0/24` - Kubernetes Worker Nodes
  - `us-west-2b`: `10.0.11.0/24` - Kubernetes Worker Nodes
  - `us-west-2c`: `10.0.12.0/24` - Kubernetes Worker Nodes

### 🖥️ **Compute Resources**

- **Kubernetes Control Plane**: Private subnets (no public IPs)
- **Kubernetes Worker Nodes**: Private subnets (no public IPs)
- **Instance Types**: Production-grade (t3.medium, t3.large, etc.)
- **Auto Scaling**: Based on workload demands

### 🔒 **Security Architecture**

- **Bastion Host**:

  - Located in public subnet
  - Restricted SSH access from specific IP ranges
  - Used to access private nodes securely

- **Security Groups**:
  - **Public SG**: Load balancers and bastion host
  - **Private SG**: Kubernetes nodes (restricted access)
  - **Database SG**: RDS instances (if applicable)

### 🌐 **Load Balancing**

- **Application Load Balancer (ALB)**:
  - Public-facing in public subnets
  - Routes external traffic to private Kubernetes nodes
  - SSL/TLS termination
  - Health checks and auto-scaling integration

### 🔗 **NAT Gateway**

- **Purpose**: Private nodes need internet access for:
  - Container image pulls
  - Software updates
  - External API calls
- **Location**: Public subnets
- **Cost**: ~$32/month per AZ (production requirement)

### 🗄️ **Additional Production Components**

- **RDS Database**: Private subnets with security groups
- **ElastiCache**: Redis/Memcached in private subnets
- **S3**: Object storage for application data
- **CloudWatch**: Monitoring and logging
- **IAM Roles**: Least privilege access for services

---

## 📊 Comparison Summary

| Component         | Development    | Production                       |
| ----------------- | -------------- | -------------------------------- |
| **VPC**           | Single AZ      | Multi-AZ                         |
| **Subnets**       | 1 Public       | 6 Subnets (3 Public + 3 Private) |
| **EC2 Instances** | 1 t3.medium    | Multiple production instances    |
| **Kubernetes**    | ✅ Single-node | ✅ Multi-node cluster            |
| **NAT Gateway**   | ❌             | ✅ (Required)                    |
| **Bastion Host**  | ❌             | ✅ (Security requirement)        |
| **Load Balancer** | ❌             | ✅ (ALB/NLB)                     |
| **Monthly Cost**  | ~$2            | ~$200-500+                       |

---

## 🚀 Migration Path

### Phase 1: Infrastructure Foundation

1. Create production VPC with multi-AZ subnets
2. Deploy NAT Gateway for private subnet internet access
3. Set up bastion host for secure access

### Phase 2: Kubernetes Cluster

1. Deploy Kubernetes control plane in private subnets
2. Add worker nodes with auto-scaling
3. Configure cluster networking and security

### Phase 3: Application Layer

1. Deploy Application Load Balancer
2. Configure ingress controllers
3. Set up monitoring and logging

### Phase 4: Production Hardening

1. Implement backup and disaster recovery
2. Add additional security measures
3. Performance optimization and scaling

---

## 📝 Notes

- **Development Environment**: Optimized for cost and simplicity
- **Production Environment**: Optimized for security, scalability, and reliability
- **Migration**: Can be done incrementally without downtime
- **Cost Management**: Use AWS Cost Explorer to monitor expenses
- **Security**: Follow AWS Well-Architected Framework best practices

---

_Last Updated: June 28, 2024_
_Environment: Development (us-west-2)_
