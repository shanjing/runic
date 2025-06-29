# Kubernetes Manifests

This directory contains raw Kubernetes YAML manifests for the Runic project.

## 📁 Organization

```
manifests/
├── namespaces/      # Namespace definitions
├── deployments/     # Deployment resources
├── services/        # Service resources
├── configmaps/      # Configuration maps
├── secrets/         # Secret templates (no actual secrets)
├── ingress/         # Ingress resources
├── storage/         # Persistent volumes and claims
└── rbac/           # Role-based access control
```

## 🎯 Usage

### Apply All Manifests

```bash
kubectl apply -f kubernetes/manifests/
```

### Apply by Category

```bash
# Apply namespaces first
kubectl apply -f kubernetes/manifests/namespaces/

# Apply RBAC
kubectl apply -f kubernetes/manifests/rbac/

# Apply storage
kubectl apply -f kubernetes/manifests/storage/

# Apply applications
kubectl apply -f kubernetes/manifests/deployments/
kubectl apply -f kubernetes/manifests/services/
```

## 📋 Best Practices

1. **Order Matters**: Apply namespaces and RBAC first
2. **Environment Variables**: Use ConfigMaps for non-sensitive data
3. **Secrets**: Use external secret management (AWS Secrets Manager, etc.)
4. **Labels**: Use consistent labeling scheme
5. **Annotations**: Document important metadata

## 🔒 Security Notes

- Never commit actual secrets to version control
- Use external secret management solutions
- Implement network policies for pod-to-pod communication
- Use security contexts and pod security policies

---

_This directory is for raw Kubernetes manifests. For complex applications, consider using Helm charts in the `helm/` directory._
