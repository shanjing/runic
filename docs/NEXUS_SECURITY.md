# Nexus Security Architecture

Security considerations for Nexus as a blockchain coordination service endpoint.

## 🛡️ Security Layers

Nexus implements **defense-in-depth** with multiple security layers:

```
Layer 1: AWS Security Groups (VPC-level firewall)
  ↓
Layer 2: Network Policies (Kubernetes-level firewall)
  ↓
Layer 3: Pod Security Context (Container isolation)
  ↓
Layer 4: RBAC (Access control)
  ↓
Layer 5: Encryption (KMS, TLS, encrypted storage)
```

---

## 🔒 Network Policy Security (Blockchain Service Endpoint)

### Enhanced Security Model

As a **blockchain coordination service**, Nexus implements strict network isolation:

```yaml
# Default: DENY ALL (baseline security)
# Then: Allow ONLY specific traffic (allowlist approach)
```

### Ingress Rules (Incoming Traffic)

| Port     | Source                                 | Purpose                   | Security Level              |
| -------- | -------------------------------------- | ------------------------- | --------------------------- |
| **8080** | ALB subnets only (`10.0.101-103.0/24`) | API endpoint              | 🔒 Restricted to ALB        |
| **9090** | Same-namespace pods only               | Consensus protocol (Raft) | 🔐 Highly restricted        |
| **9091** | Monitoring namespace                   | Prometheus metrics        | 🔒 Restricted to monitoring |

**Key Point:** Consensus port (9090) is **never exposed** externally - only pod-to-pod within namespace!

### Egress Rules (Outgoing Traffic)

| Port     | Destination                       | Purpose                         | Security Level       |
| -------- | --------------------------------- | ------------------------------- | -------------------- |
| **53**   | kube-system namespace             | DNS resolution                  | ✅ Required          |
| **9090** | Nexus pods                        | Consensus replication           | ✅ Required          |
| **5432** | Private subnets (`10.0.1-3.0/24`) | PostgreSQL database             | 🔒 DB subnets only   |
| **443**  | VPC only (`10.0.0.0/16`)          | AWS APIs (KMS, Secrets Manager) | 🔒 Internal VPC only |

**Key Point:** No direct internet access - all AWS API calls go through VPC endpoints!

---

## 🎯 Why This Matters for Blockchain

### Critical Assets Protected:

1. **State Ledger**: PostgreSQL contains off-chain state transitions
2. **Cryptographic Keys**: Managed via AWS KMS
3. **Consensus Protocol**: Raft/Tendermint communication on port 9090
4. **API Endpoints**: Public API requires careful access control

### Threat Model:

| Threat                | Mitigation                                         |
| --------------------- | -------------------------------------------------- |
| **Pod compromise**    | ReadOnlyRootFilesystem, no privilege escalation    |
| **Network sniffing**  | mTLS for consensus, TLS for API                    |
| **Lateral movement**  | NetworkPolicy blocks pod-to-pod (except consensus) |
| **Data exfiltration** | Egress restricted to VPC only                      |
| **Consensus attack**  | Port 9090 isolated, quorum required                |
| **Key theft**         | KMS with IRSA, keys never touch disk               |

---

## 🔐 Security Configuration Details

### 1. Pod Security Context

**Pod-level:**

```yaml
podSecurityContext:
  runAsNonRoot: true # Cannot run as root
  runAsUser: 1000 # Specific UID
  fsGroup: 1000 # File ownership
  seccompProfile:
    type: RuntimeDefault # Syscall filtering
```

**Container-level:**

```yaml
securityContext:
  allowPrivilegeEscalation: false # Cannot gain privileges
  readOnlyRootFilesystem: true # Immutable filesystem
  capabilities:
    drop: [ALL] # Remove all Linux capabilities
```

**Writable locations (only 2):**

- `/var/lib/nexus` - PVC for state data
- `/tmp` - emptyDir for temporary files

---

### 2. Network Isolation

**Strict Ingress:**

```yaml
# Port 8080: Only from ALB subnets
- from:
    - ipBlock:
        cidr: 10.0.101.0/24 # ALB subnet 1
    - ipBlock:
        cidr: 10.0.102.0/24 # ALB subnet 2
    - ipBlock:
        cidr: 10.0.103.0/24 # ALB subnet 3

# Port 9090: ONLY from same-namespace Nexus pods
- from:
    - podSelector:
        matchLabels:
          app: nexus
          component: coordination
```

**Strict Egress:**

```yaml
# Database: Only private subnets
- to:
    - ipBlock:
        cidr: 10.0.1.0/24 # RDS subnet 1
    - ipBlock:
        cidr: 10.0.2.0/24 # RDS subnet 2
    - ipBlock:
        cidr: 10.0.3.0/24 # RDS subnet 3
  ports:
    - port: 5432

# AWS APIs: Only within VPC (via VPC endpoints)
- to:
    - ipBlock:
        cidr: 10.0.0.0/16 # VPC CIDR
  ports:
    - port: 443
```

**What's blocked:**

- ❌ Direct internet access
- ❌ Access to other namespaces (except kube-system DNS)
- ❌ Unrestricted egress
- ❌ External consensus connections

---

### 3. IRSA (IAM Roles for Service Accounts)

**Service Account:**

```yaml
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/nexus-sa-role
```

**Permissions (least-privilege):**

```json
{
  "Effect": "Allow",
  "Action": [
    "kms:Decrypt",
    "kms:Encrypt",
    "kms:GenerateDataKey", // Key operations only
    "secretsmanager:GetSecretValue" // Read secrets only
  ],
  "Resource": ["specific-kms-key-arn", "specific-secret-arn"]
}
```

**What's NOT allowed:**

- ❌ EC2 operations
- ❌ S3 access
- ❌ IAM modifications
- ❌ KMS admin operations

---

### 4. Data Encryption

**At Rest:**

- ✅ RDS: Encrypted with KMS
- ✅ EBS volumes: Encrypted with KMS
- ✅ Secrets: Encrypted in Secrets Manager with KMS

**In Transit:**

- ✅ API: TLS 1.2+ (via ALB)
- ✅ Consensus: mTLS between pods (configurable)
- ✅ Database: SSL/TLS to RDS

---

## 🎯 Blockchain-Specific Security Considerations

### For a Blockchain Coordination Service:

#### 1. **Consensus Integrity**

```yaml
# Port 9090 must NEVER be exposed externally
networkPolicy:
  ingress:
    - from:
        - podSelector: # Only same pods
            matchLabels:
              app: nexus
      ports:
        - port: 9090
```

#### 2. **State Ledger Protection**

```yaml
# Database access restricted to private subnets only
egress:
  - to:
      - ipBlock:
          cidr: 10.0.1.0/24 # Private subnet only
    ports:
      - port: 5432
```

#### 3. **Key Management**

```yaml
# AWS KMS access via VPC endpoints only (no internet)
egress:
  - to:
      - ipBlock:
          cidr: 10.0.0.0/16 # VPC only
    ports:
      - port: 443
```

#### 4. **API Rate Limiting** (ALB-level)

```yaml
annotations:
  # Add WAF for rate limiting (optional)
  alb.ingress.kubernetes.io/wafv2-acl-arn: arn:aws:wafv2:...
```

---

## 🔍 Security Audit Checklist

### Before Going to Production:

- [ ] **Network Policy**: Verify subnet CIDRs match your actual VPC subnets
- [ ] **IRSA**: Confirm IAM role has minimal required permissions
- [ ] **TLS**: Add ACM certificate ARN to ingress annotations
- [ ] **WAF**: Consider adding AWS WAF for DDoS protection
- [ ] **Secrets**: Use External Secrets Operator, not static secrets
- [ ] **Audit Logging**: Enable EKS control plane logging
- [ ] **Image Scanning**: Scan `runic/nexus` image for vulnerabilities
- [ ] **Pod Security Admission**: Enable restricted pod security standard
- [ ] **RBAC**: Review service account permissions
- [ ] **Monitoring**: Set up alerts for security events

### Regular Security Maintenance:

- [ ] **Monthly**: Rotate database credentials
- [ ] **Monthly**: Review network policy logs
- [ ] **Quarterly**: Security audit of IAM roles
- [ ] **Quarterly**: Update Kubernetes version
- [ ] **Quarterly**: Scan and update container images

---

## 🚨 Security Incident Response

If you suspect a compromise:

```bash
# 1. Isolate the pod immediately
kubectl delete pod nexus-cluster-0 -n coordination-system

# 2. Check audit logs
kubectl logs nexus-cluster-0 -n coordination-system --previous > incident-logs.txt

# 3. Review network policy violations (if enabled)
kubectl get events -n coordination-system | grep NetworkPolicy

# 4. Check RDS access logs
aws rds describe-db-log-files --db-instance-identifier nexus-coordination-cluster-db

# 5. Review CloudTrail for AWS API calls
aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=nexus-sa-role
```

---

## 📊 Security Comparison

| Configuration             | Security Level | Trade-off                  |
| ------------------------- | -------------- | -------------------------- |
| **Current (Enhanced)**    | 🔒 High        | Requires VPC subnet CIDRs  |
| **Previous (Permissive)** | ⚠️ Medium      | Easy setup, less secure    |
| **Maximum (egress deny)** | 🔐 Very High   | Complex, maintenance heavy |

---

## 🎯 Summary of Enhanced Security

### What Changed:

**Before:**

- ❌ Ingress from `ingress-nginx` namespace (doesn't exist with ALB)
- ❌ Egress to any destination on 443 (too broad)
- ❌ Duplicate egress rules

**After:**

- ✅ Ingress restricted to ALB subnet CIDRs only
- ✅ Egress to RDS restricted to private subnets only
- ✅ Egress to AWS APIs restricted to VPC only (no internet)
- ✅ Consensus traffic isolated to pod-to-pod
- ✅ DNS includes both TCP and UDP
- ✅ Comments explain blockchain-specific requirements

### Result:

A **prototype-oriented, blockchain-appropriate** network policy that:

1. Protects consensus protocol from external access
2. Restricts database access to known subnets
3. Prevents internet egress (AWS APIs via VPC endpoints)
4. Follows zero-trust principles

**This is now appropriate for a blockchain coordination service endpoint!** 🎯
