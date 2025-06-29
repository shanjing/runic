# Kubernetes Configurations

This directory contains Kubernetes configuration files and context management.

## 📁 Directory Structure

```
configs/
├── kubeconfig          # Cluster access configuration
├── contexts/           # Multiple cluster contexts
├── namespaces/         # Namespace definitions
├── resource-quotas/    # Resource limits and requests
└── templates/          # Configuration templates
```

## 🎯 Purpose

- **kubeconfig**: Primary cluster access configuration
- **contexts**: Multiple cluster management
- **namespaces**: Namespace organization
- **resource-quotas**: Resource management
- **templates**: Reusable configuration templates

## 🚀 Usage

### Kubeconfig Management

#### Copy from Cluster

```bash
# Copy kubeconfig from your cluster
scp -i your-key.pem ubuntu@<cluster-ip>:/home/ubuntu/.kube/config kubernetes/configs/kubeconfig

# Use the kubeconfig
export KUBECONFIG=kubernetes/configs/kubeconfig
kubectl get nodes
```

#### Multiple Clusters

```bash
# Set up multiple contexts
kubectl config set-cluster runic-dev --server=https://<dev-cluster-ip>:6443
kubectl config set-context runic-dev --cluster=runic-dev --user=admin
kubectl config use-context runic-dev

# Switch between contexts
kubectl config use-context runic-prod
kubectl config use-context runic-dev
```

### Namespace Management

#### Create Namespaces

```bash
# Apply namespace definitions
kubectl apply -f kubernetes/configs/namespaces/

# Set default namespace
kubectl config set-context --current --namespace=my-app
```

#### Resource Quotas

```bash
# Apply resource quotas
kubectl apply -f kubernetes/configs/resource-quotas/

# Check quota usage
kubectl describe resourcequota
```

## 📋 Configuration Examples

### kubeconfig

```yaml
apiVersion: v1
kind: Config
clusters:
  - name: runic-dev
    cluster:
      server: https://<cluster-ip>:6443
      certificate-authority-data: <base64-ca-cert>
contexts:
  - name: runic-dev
    context:
      cluster: runic-dev
      user: admin
current-context: runic-dev
users:
  - name: admin
    user:
      client-certificate-data: <base64-cert>
      client-key-data: <base64-key>
```

### Namespace Definition

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    app: my-app
    environment: development
```

### Resource Quota

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: my-app-quota
  namespace: my-app
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "5"
```

## 🔧 Best Practices

### Security

- **Access Control**: Use service accounts with least privilege
- **Certificate Rotation**: Regularly rotate certificates
- **Network Policies**: Implement pod-to-pod communication policies
- **RBAC**: Use role-based access control

### Organization

- **Environment Separation**: Use different contexts for different environments
- **Namespace Isolation**: Separate applications by namespace
- **Resource Limits**: Set appropriate resource quotas
- **Documentation**: Document configuration changes

### Backup

- **Regular Backups**: Backup kubeconfig and important configurations
- **Version Control**: Track configuration changes in git
- **Testing**: Test configurations in non-production environments

## 🔒 Security Notes

### Sensitive Information

- Never commit actual certificates or tokens to version control
- Use external secret management for sensitive data
- Rotate credentials regularly
- Implement audit logging

### Access Management

- Use service accounts instead of user accounts for applications
- Implement least privilege access
- Use network policies for pod communication
- Monitor access patterns

## 📊 Monitoring

### Configuration Validation

```bash
# Validate kubeconfig
kubectl config view

# Check current context
kubectl config current-context

# List all contexts
kubectl config get-contexts
```

### Resource Usage

```bash
# Check resource quotas
kubectl describe resourcequota

# Check namespace usage
kubectl top pods --all-namespaces
```

---

_Keep configurations secure and well-documented. Regular backups and testing are essential._
