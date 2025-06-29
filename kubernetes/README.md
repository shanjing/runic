# Kubernetes Resources

This directory contains all Kubernetes-related resources for the Runic project, organized for clarity and maintainability.

## 📁 Directory Structure

```
kubernetes/
├── helm/           # Helm charts for application deployment
├── manifests/      # Raw Kubernetes YAML manifests
├── configs/        # Kubernetes configurations (kubeconfig, contexts, etc.)
└── scripts/        # Kubernetes-related utility scripts
```

## 🎯 Purpose

- **Helm Charts**: For complex applications with multiple components
- **Raw Manifests**: For simple resources or custom configurations
- **Configs**: For cluster configurations and contexts
- **Scripts**: For automation and maintenance tasks

## 🚀 Usage

### Deploying Applications

#### Using Helm Charts

```bash
# Navigate to helm directory
cd kubernetes/helm

# Install a chart
helm install my-app ./my-app-chart

# Upgrade a chart
helm upgrade my-app ./my-app-chart

# Uninstall a chart
helm uninstall my-app
```

#### Using Raw Manifests

```bash
# Apply all manifests in a directory
kubectl apply -f kubernetes/manifests/

# Apply specific manifest
kubectl apply -f kubernetes/manifests/my-app.yaml

# Delete resources
kubectl delete -f kubernetes/manifests/my-app.yaml
```

### Managing Configurations

#### Kubeconfig Management

```bash
# Copy kubeconfig from cluster
scp -i your-key.pem ubuntu@<cluster-ip>:/home/ubuntu/.kube/config kubernetes/configs/kubeconfig

# Use specific kubeconfig
export KUBECONFIG=kubernetes/configs/kubeconfig
kubectl get nodes
```

#### Context Management

```bash
# List contexts
kubectl config get-contexts

# Switch context
kubectl config use-context runic-dev

# Set namespace
kubectl config set-context --current --namespace=my-app
```

## 📋 Best Practices

### File Organization

- **Namespaced Resources**: Group by namespace
- **Resource Types**: Group by kind (deployments, services, etc.)
- **Applications**: Group by application name
- **Environments**: Use subdirectories for different environments

### Naming Conventions

- **Files**: Use kebab-case (e.g., `my-app-deployment.yaml`)
- **Resources**: Use descriptive names with environment prefix
- **Labels**: Use consistent label schemes
- **Annotations**: Document important metadata

### Security

- **Secrets**: Never commit secrets to version control
- **RBAC**: Use least privilege access
- **Network Policies**: Implement network segmentation
- **Pod Security**: Use security contexts and policies

## 🔧 Development Workflow

### 1. Local Development

```bash
# Start local cluster (if needed)
minikube start

# Apply development manifests
kubectl apply -f kubernetes/manifests/dev/

# Test locally
kubectl port-forward svc/my-app 8080:80
```

### 2. Testing

```bash
# Apply test manifests
kubectl apply -f kubernetes/manifests/test/

# Run tests
kubectl exec -it test-pod -- npm test

# Clean up
kubectl delete -f kubernetes/manifests/test/
```

### 3. Production Deployment

```bash
# Apply production manifests
kubectl apply -f kubernetes/manifests/prod/

# Verify deployment
kubectl get pods -n production
kubectl get svc -n production
```

## 📊 Monitoring and Debugging

### Common Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check specific resources
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods
```

### Troubleshooting

```bash
# Check pod status
kubectl get pods -o wide

# Check service endpoints
kubectl get endpoints

# Check network policies
kubectl get networkpolicies

# Check persistent volumes
kubectl get pv,pvc
```

## 🛠️ Tools and Utilities

### Scripts

- **deploy.sh**: Automated deployment script
- **cleanup.sh**: Resource cleanup script
- **backup.sh**: Configuration backup script
- **health-check.sh**: Cluster health monitoring

### Configurations

- **kubeconfig**: Cluster access configuration
- **contexts**: Multiple cluster contexts
- **namespaces**: Namespace definitions
- **resource-quotas**: Resource limits and requests

## 📚 Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Security Best Practices](https://kubernetes.io/docs/concepts/security/)

---

_Last Updated: June 28, 2024_
