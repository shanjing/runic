# Nexus Kubernetes Manifests

This directory contains Kubernetes manifests for deploying the State Coordination Service (Nexus) to a Kubernetes cluster.

## Files Overview

| File                       | Description                                 |
| -------------------------- | ------------------------------------------- |
| `namespace.yaml`           | Creates the `coordination-system` namespace |
| `serviceaccount.yaml`      | Service account with IRSA for AWS access    |
| `configmap.yaml`           | Application configuration                   |
| `secret.yaml`              | Sensitive data (credentials, keys)          |
| `statefulset.yaml`         | StatefulSet for Nexus pods (3 replicas)       |
| `service.yaml`             | Services for API, consensus, and metrics    |
| `poddisruptionbudget.yaml` | PDB to maintain quorum during disruptions   |
| `networkpolicy.yaml`       | Network policies for security isolation     |
| `servicemonitor.yaml`      | Prometheus ServiceMonitor for metrics       |
| `ingress.yaml`             | ALB Ingress for external API access         |
| `kustomization.yaml`       | Kustomize configuration                     |

## Prerequisites

1. **EKS cluster** running (deployed via Terraform)
2. **kubectl** configured to access the cluster
3. **AWS Load Balancer Controller** installed
4. **Prometheus Operator** installed (for ServiceMonitor)
5. **cert-manager** (optional, for TLS)
6. **ExternalDNS** (optional, for DNS management)

## Deployment

### Option 1: Using kubectl

```bash
# Deploy all manifests
kubectl apply -f .

# Or deploy in order
kubectl apply -f namespace.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f statefulset.yaml
kubectl apply -f service.yaml
kubectl apply -f poddisruptionbudget.yaml
kubectl apply -f networkpolicy.yaml
kubectl apply -f servicemonitor.yaml
kubectl apply -f ingress.yaml
```

### Option 2: Using Kustomize

```bash
# Apply using kustomize
kubectl apply -k .

# Preview changes
kubectl diff -k .

# Delete all resources
kubectl delete -k .
```

### Option 3: Using Helm (recommended)

See `kubernetes/helm/charts/nexus/` for Helm chart deployment.

## Before Deployment

### 1. Update Secrets

Edit `secret.yaml` and replace placeholder values:

```bash
# Get RDS credentials from Terraform output
terraform -chdir=terraform/envs/scs output -json | jq -r '.rds_credentials_secret_arn.value'

# Get secret from AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id <SECRET_ARN> \
  --query SecretString \
  --output text | jq .
```

**Better approach**: Use External Secrets Operator to sync from AWS Secrets Manager automatically.

### 2. Update ServiceAccount

Get the IAM role ARN from Terraform:

```bash
terraform -chdir=terraform/envs/scs output -raw scs_service_account_role_arn
```

Update `serviceaccount.yaml` with the role ARN.

### 3. Update Ingress

Update `ingress.yaml` with your domain and certificate ARN:

```yaml
- host: scs-api.example.com # Your domain
# alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...  # Your ACM cert
```

### 4. Verify Storage Class

Ensure `gp3` storage class exists:

```bash
kubectl get storageclass gp3
```

If not, create it:

```bash
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

## Verification

### Check Deployment Status

```bash
# Watch pods coming up
kubectl get pods -n coordination-system -w

# Check StatefulSet
kubectl get statefulset -n coordination-system

# Check services
kubectl get svc -n coordination-system

# Check PVCs
kubectl get pvc -n coordination-system

# Check ingress
kubectl get ingress -n coordination-system
```

### Check Pod Health

```bash
# Describe a pod
kubectl describe pod scs-cluster-0 -n coordination-system

# Check logs
kubectl logs scs-cluster-0 -n coordination-system

# Exec into a pod
kubectl exec -it scs-cluster-0 -n coordination-system -- /bin/sh
```

### Test API Endpoint

```bash
# Port-forward to test locally
kubectl port-forward svc/scs-api 8080:8080 -n coordination-system

# Test health endpoint
curl http://localhost:8080/health/ready

# Get ALB endpoint
kubectl get ingress scs-api-ingress -n coordination-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Test via ALB
curl http://<ALB_ENDPOINT>/health/ready
```

### Check Consensus

```bash
# Check if pods can communicate
kubectl exec -it scs-cluster-0 -n coordination-system -- \
  nc -zv scs-cluster-1.scs-headless.coordination-system.svc.cluster.local 9090

# View consensus logs
kubectl logs scs-cluster-0 -n coordination-system | grep -i consensus
```

### Check Metrics

```bash
# Port-forward metrics endpoint
kubectl port-forward svc/scs-api 9091:9091 -n coordination-system

# View metrics
curl http://localhost:9091/metrics
```

## Scaling

### Manual Scaling

```bash
# Scale to 5 replicas
kubectl scale statefulset scs-cluster --replicas=5 -n coordination-system

# Scale back to 3
kubectl scale statefulset scs-cluster --replicas=3 -n coordination-system
```

### Update Configuration

```bash
# Edit ConfigMap
kubectl edit configmap scs-config -n coordination-system

# Restart pods to pick up changes
kubectl rollout restart statefulset scs-cluster -n coordination-system
```

## Updates and Rollback

### Rolling Update

```bash
# Update image
kubectl set image statefulset/scs-cluster \
  scs-node=runic/scs:v1.1.0 \
  -n coordination-system

# Check rollout status
kubectl rollout status statefulset/scs-cluster -n coordination-system

# View rollout history
kubectl rollout history statefulset/scs-cluster -n coordination-system
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo statefulset/scs-cluster -n coordination-system

# Rollback to specific revision
kubectl rollout undo statefulset/scs-cluster --to-revision=2 -n coordination-system
```

## Troubleshooting

### Pods Not Starting

```bash
# Check events
kubectl get events -n coordination-system --sort-by='.lastTimestamp'

# Check pod status
kubectl describe pod scs-cluster-0 -n coordination-system

# Check logs
kubectl logs scs-cluster-0 -n coordination-system --previous
```

### PVC Issues

```bash
# Check PVC status
kubectl get pvc -n coordination-system

# Check storage class
kubectl get storageclass

# Describe PVC
kubectl describe pvc scs-data-scs-cluster-0 -n coordination-system
```

### Database Connection Issues

```bash
# Test DB connectivity from pod
kubectl exec -it scs-cluster-0 -n coordination-system -- \
  psql -h <RDS_ENDPOINT> -U scsadmin -d scsdb

# Check secrets
kubectl get secret scs-secrets -n coordination-system -o yaml
```

### Network Policy Issues

```bash
# Check network policies
kubectl get networkpolicy -n coordination-system

# Temporarily disable network policies for testing
kubectl delete networkpolicy --all -n coordination-system

# Re-apply after testing
kubectl apply -f networkpolicy.yaml
```

### Ingress/ALB Issues

```bash
# Check ingress status
kubectl describe ingress scs-api-ingress -n coordination-system

# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check target group health in AWS Console
```

## Cleanup

### Delete Nexus Resources

```bash
# Delete all Nexus resources
kubectl delete -k .

# Or delete namespace (will delete everything in it)
kubectl delete namespace coordination-system
```

### Delete PVCs Manually

```bash
# StatefulSet deletion doesn't delete PVCs automatically
kubectl delete pvc -n coordination-system -l app=scs
```

## Security Considerations

1. **Secrets Management**: Use External Secrets Operator or AWS Secrets Manager CSI driver
2. **Network Policies**: Review and adjust based on your security requirements
3. **RBAC**: Implement least-privilege service accounts
4. **Pod Security**: Enabled securityContext, runAsNonRoot, readOnlyRootFilesystem
5. **TLS**: Configure TLS for all communication (API, consensus)
6. **Audit Logging**: Enable Kubernetes audit logs
7. **Image Scanning**: Scan container images for vulnerabilities

## Performance Tuning

### Resource Limits

Adjust based on workload:

```yaml
resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    cpu: 4000m
    memory: 8Gi
```

### Storage

For better IOPS, consider io2 storage class:

```yaml
storageClassName: io2
```

### Node Affinity

Pin to specific instance types:

```yaml
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      - matchExpressions:
          - key: node.kubernetes.io/instance-type
            operator: In
            values:
              - m5.xlarge
              - m5.2xlarge
```

## Monitoring

### Prometheus Queries

```promql
# Pod CPU usage
rate(container_cpu_usage_seconds_total{namespace="coordination-system"}[5m])

# Pod memory usage
container_memory_working_set_bytes{namespace="coordination-system"}

# Request rate
rate(http_requests_total{namespace="coordination-system"}[5m])

# Error rate
rate(http_requests_total{namespace="coordination-system",status=~"5.."}[5m])
```

### Grafana Dashboard

Import the Nexus dashboard from `kubernetes/configs/grafana/scs-dashboard.json`

## References

- Architecture: `docs/nexus-architecture.md`
- Terraform: `terraform/envs/scs/`
- Helm Charts: `kubernetes/helm/charts/nexus/`
