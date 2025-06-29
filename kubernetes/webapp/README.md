# Webapp Example - Resource Optimization & Cost Control

## Overview

Example deployment demonstrating resource allocation and cost optimization for development environments.

## Key Features

### Resource Management

- **Moderate Resource Limits**: 200m CPU, 512Mi memory per pod
- **Conservative Requests**: 160m CPU, 400Mi memory (80% of limits)
- **HPA Scaling**: 75% CPU utilization threshold, 1-6 replicas
- **Node Capacity**: Optimized for t3.medium (2 vCPU, 4GB RAM)

### Cost Optimization

- **Single AZ Deployment**: Pod affinity ensures all replicas run in same AZ
- **No Inter-AZ Charges**: Avoids $0.02/GB data transfer costs
- **Development Focus**: Single node cluster with control plane tolerations

### Architecture

- **Container**: nginx:1-alpine on port 8080
- **Service**: NodePort (30080) for external access
- **Namespace**: Isolated `webapp` namespace
- **Region**: us-west-2 node affinity

## Usage

```bash
kubectl apply -f webapp.yaml
kubectl get pods -n webapp
kubectl get svc -n webapp
```

## Access

- External: `http://<EC2_IP>:30080`
- Internal: `http://webapp-service.webapp.svc.cluster.local`

## Resource Estimation

With moderate limits, approximately 6-8 pods (2 containers each) can run safely on t3.medium node.
