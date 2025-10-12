# Nexus Installation Guide

Quick reference for installing Nexus from the local repository.

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.5.0
- kubectl >= 1.24
- Helm >= 3.8
- jq (for JSON processing)

## Installation Methods

### Method 1: Automated Full Stack Deployment ⭐ Recommended

Deploys complete infrastructure (Terraform) + application (Helm) in one command:

```bash
# Clone repository
git clone https://github.com/shanjing/runic.git
cd runic

# Run automated deployment
./scripts/deploy-nexus.sh
```

**What it does:**
1. ✅ Checks prerequisites
2. ✅ Deploys Terraform infrastructure (VPC, EKS, RDS, KMS)
3. ✅ Configures kubectl
4. ✅ Retrieves RDS credentials from AWS Secrets Manager
5. ✅ Deploys Helm chart with auto-configured values
6. ✅ Verifies deployment

**Time:** ~20-30 minutes

---

### Method 2: Manual Step-by-Step Deployment

For more control over each step:

#### Step 1: Clone Repository

```bash
git clone https://github.com/shanjing/runic.git
cd runic
```

#### Step 2: Deploy Infrastructure with Terraform

```bash
cd terraform/envs/nexus

# Initialize
terraform init

# Review plan
terraform plan

# Apply (creates VPC, EKS, RDS, KMS)
terraform apply
```

#### Step 3: Configure kubectl

```bash
# Get cluster name from Terraform output
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name $CLUSTER_NAME

# Verify
kubectl get nodes
```

#### Step 4: Get Database Credentials

```bash
# Get secret ARN
SECRET_ARN=$(terraform output -raw rds_credentials_secret_arn)

# Retrieve credentials
aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text | jq .
```

#### Step 5: Deploy with Helm

**Option A: Quick install with defaults**

```bash
# From repository root
helm install nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --create-namespace
```

**Option B: Install with custom values**

Create `my-values.yaml`:

```yaml
image:
  repository: ghcr.io/shanjing/nexus
  tag: v1.0.0

secrets:
  database:
    host: "your-rds-endpoint.us-west-2.rds.amazonaws.com"
    password: "YOUR_PASSWORD"

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/nexus-sa-role"
```

Deploy:

```bash
helm install nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --create-namespace \
  -f my-values.yaml
```

**Option C: Install with inline values**

```bash
helm install nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --create-namespace \
  --set secrets.database.host="your-rds-endpoint.us-west-2.rds.amazonaws.com" \
  --set secrets.database.password="YOUR_PASSWORD" \
  --set image.tag="v1.0.0"
```

---

### Method 3: Raw Kubernetes Manifests

For environments without Helm:

```bash
# Update manifests with your values
cd kubernetes/manifests/nexus

# Edit secret.yaml with your credentials
vim secret.yaml

# Apply all manifests
kubectl apply -k .

# Or apply individually
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

---

## Installation Verification

### Check Deployment Status

```bash
# Check all resources
kubectl get all -n coordination-system

# Check pods
kubectl get pods -n coordination-system -w

# Wait for pods to be ready
kubectl wait --for=condition=ready pod \
  -l app=nexus \
  -n coordination-system \
  --timeout=300s
```

### Check StatefulSet

```bash
# Check StatefulSet status
kubectl get statefulset nexus-cluster -n coordination-system

# Should show: READY 3/3
```

### Check Services

```bash
# List services
kubectl get svc -n coordination-system

# Should show:
# - nexus-api (ClusterIP)
# - nexus-headless (ClusterIP None)
# - nexus-consensus (ClusterIP None)
```

### Check PVCs

```bash
# List persistent volume claims
kubectl get pvc -n coordination-system

# Should show 3 PVCs in Bound state
```

### Test API Endpoint

```bash
# Port-forward to test locally
kubectl port-forward svc/nexus-api 8080:8080 -n coordination-system

# In another terminal, test
curl http://localhost:8080/health/ready
curl http://localhost:8080/health/live
```

### Check Logs

```bash
# Follow logs from all pods
kubectl logs -f statefulset/nexus-cluster -n coordination-system

# Check specific pod
kubectl logs nexus-cluster-0 -n coordination-system
```

---

## Common Installation Issues

### Issue: Terraform State Lock

```bash
# If you see "Error acquiring state lock"
terraform force-unlock <LOCK_ID>
```

### Issue: Pods Not Starting

```bash
# Describe pod to see events
kubectl describe pod nexus-cluster-0 -n coordination-system

# Check events
kubectl get events -n coordination-system --sort-by='.lastTimestamp'
```

### Issue: PVC Not Binding

```bash
# Check storage class exists
kubectl get storageclass gp3

# If not, create it
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

### Issue: Database Connection Failed

```bash
# Verify RDS is accessible
aws rds describe-db-instances \
  --db-instance-identifier nexus-coordination-cluster-db

# Check security groups allow traffic from EKS to RDS on port 5432
```

---

## Post-Installation

### Configure Ingress Domain

Update ingress with your domain:

```bash
helm upgrade nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --set ingress.hosts[0].host=nexus.yourdomain.com
```

### Enable TLS

```bash
helm upgrade nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --set ingress.tls[0].secretName=nexus-tls \
  --set ingress.tls[0].hosts[0]=nexus.yourdomain.com \
  --set ingress.annotations."alb\.ingress\.kubernetes\.io/certificate-arn"="arn:aws:acm:us-west-2:123456789012:certificate/xxxxx"
```

### Scale Replicas

```bash
# Scale to 5 replicas
helm upgrade nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --set replicaCount=5
```

### Update Resources

```bash
helm upgrade nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --set resources.requests.cpu=1000m \
  --set resources.requests.memory=2Gi
```

---

## Uninstallation

### Quick Cleanup

```bash
# Run automated cleanup script
./scripts/destroy-nexus.sh
```

### Manual Cleanup

```bash
# 1. Uninstall Helm release
helm uninstall nexus -n coordination-system

# 2. Delete PVCs (not auto-deleted)
kubectl delete pvc -n coordination-system -l app=nexus

# 3. Delete namespace
kubectl delete namespace coordination-system

# 4. Disable RDS deletion protection
aws rds modify-db-instance \
  --db-instance-identifier nexus-coordination-cluster-db \
  --no-deletion-protection \
  --apply-immediately

# 5. Destroy Terraform infrastructure
cd terraform/envs/nexus
terraform destroy
```

---

## Quick Reference

| Task | Command |
|------|---------|
| **Full deployment** | `./scripts/deploy-nexus.sh` |
| **Helm install** | `helm install nexus ./kubernetes/helm/charts/nexus -n coordination-system --create-namespace` |
| **Check status** | `kubectl get all -n coordination-system` |
| **View logs** | `kubectl logs -f statefulset/nexus-cluster -n coordination-system` |
| **Port-forward** | `kubectl port-forward svc/nexus-api 8080:8080 -n coordination-system` |
| **Update Helm** | `helm upgrade nexus ./kubernetes/helm/charts/nexus -n coordination-system` |
| **Uninstall** | `./scripts/destroy-nexus.sh` |

---

## Next Steps

1. ✅ Configure monitoring (Prometheus/Grafana)
2. ✅ Set up DNS and TLS certificates
3. ✅ Configure backup strategy
4. ✅ Set up CI/CD pipeline
5. ✅ Review security settings
6. ✅ Load test the system

For detailed documentation, see:
- `docs/nexus-architecture.md` - Architecture overview
- `docs/nexus-deployment-guide.md` - Full deployment guide
- `docs/nexus-quick-reference.md` - Daily operations

