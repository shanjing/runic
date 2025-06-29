# Kubernetes Scripts

This directory contains utility scripts for Kubernetes cluster management and automation.

## 📁 Available Scripts

### Cluster Management

- **deploy.sh**: Automated deployment script
- **cleanup.sh**: Resource cleanup script
- **backup.sh**: Configuration backup script
- **health-check.sh**: Cluster health monitoring

### Development

- **port-forward.sh**: Port forwarding for local development
- **logs.sh**: Log aggregation and viewing
- **exec.sh**: Interactive pod execution

### Maintenance

- **update.sh**: Cluster updates and upgrades
- **scale.sh**: Application scaling
- **restart.sh**: Pod restart utilities

## 🚀 Usage

### Make Scripts Executable

```bash
chmod +x kubernetes/scripts/*.sh
```

### Run Scripts

```bash
# Deploy applications
./kubernetes/scripts/deploy.sh

# Check cluster health
./kubernetes/scripts/health-check.sh

# Clean up resources
./kubernetes/scripts/cleanup.sh
```

## 📋 Script Examples

### deploy.sh

```bash
#!/bin/bash
# Deploy all applications to the cluster

echo "🚀 Deploying applications..."

# Apply namespaces
kubectl apply -f ../manifests/namespaces/

# Apply RBAC
kubectl apply -f ../manifests/rbac/

# Apply storage
kubectl apply -f ../manifests/storage/

# Apply applications
kubectl apply -f ../manifests/deployments/
kubectl apply -f ../manifests/services/

echo "✅ Deployment complete!"
```

### health-check.sh

```bash
#!/bin/bash
# Check cluster health and status

echo "🏥 Checking cluster health..."

# Check nodes
echo "📊 Node Status:"
kubectl get nodes

# Check pods
echo "📦 Pod Status:"
kubectl get pods --all-namespaces

# Check services
echo "🌐 Service Status:"
kubectl get svc --all-namespaces

# Check events
echo "📋 Recent Events:"
kubectl get events --sort-by='.lastTimestamp' --tail=10
```

## 🔧 Customization

### Environment Variables

Set these in your shell or script:

```bash
export KUBECONFIG=../configs/kubeconfig
export NAMESPACE=my-app
export CLUSTER_NAME=runic-dev
```

### Script Parameters

```bash
# Deploy specific application
./deploy.sh my-app

# Check specific namespace
./health-check.sh my-namespace

# Scale specific deployment
./scale.sh my-deployment 3
```

## 📊 Monitoring

### Log Aggregation

```bash
# View logs from multiple pods
./kubernetes/scripts/logs.sh my-app

# Follow logs in real-time
./kubernetes/scripts/logs.sh my-app -f
```

### Resource Monitoring

```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Check persistent volumes
kubectl get pv,pvc
```

## 🔒 Security

### Access Control

- Use service accounts with least privilege
- Implement RBAC policies
- Use network policies for pod communication

### Secret Management

- Never hardcode secrets in scripts
- Use external secret management
- Rotate credentials regularly

---

_These scripts are for automation and convenience. Always review and test before running in production._
