# Nexus File Structure and Functions

Complete reference of all Nexus-related files in the Runic repository.

## 📚 Documentation (`docs/`)

| File                            | Function                                                                    |
| ------------------------------- | --------------------------------------------------------------------------- |
| **`nexus-architecture.md`**     | Complete architecture overview - K8s components, security, operational flow |
| **`nexus-deployment-guide.md`** | Step-by-step deployment instructions, troubleshooting, cost management      |
| **`nexus-quick-reference.md`**  | Quick command reference, common operations, troubleshooting snippets        |
| **`NEXUS_RENAME.md`**           | Migration documentation from SCS to Nexus                                   |
| **`COMMIT_MESSAGE.md`**         | Prepared commit message for initial release                                 |

## 🎯 Terraform Infrastructure (`terraform/envs/nexus/`)

### Core Configuration Files

| File                   | Function                                                                |
| ---------------------- | ----------------------------------------------------------------------- |
| **`main.tf`**          | Main infrastructure - VPC, EKS, RDS, KMS, IAM roles, namespace creation |
| **`provider.tf`**      | Terraform and provider configuration (AWS, Kubernetes, Helm)            |
| **`variables.tf`**     | All configurable variables with defaults and descriptions               |
| **`outputs.tf`**       | Outputs for cluster info, RDS endpoints, IAM roles, kubectl config      |
| **`terraform.tfvars`** | Default values for the Nexus environment                                |
| **`config`**           | Environment configuration in shell format                               |
| **`README.md`**        | Terraform-specific deployment guide and reference                       |
| **`.gitignore`**       | Terraform state and sensitive files exclusions                          |

### What It Creates

- **VPC**: 3 AZs with public/private subnets, NAT gateways, route tables
- **EKS**: Kubernetes 1.28 cluster with managed node group (3-10 nodes)
- **RDS**: PostgreSQL 15.4 Multi-AZ instance with encrypted storage
- **KMS**: Encryption keys for data at rest
- **IAM**: IRSA roles for service account authentication
- **Secrets**: RDS credentials stored in AWS Secrets Manager
- **K8s Resources**: Namespace and service account with IRSA annotations

## ☸️ Kubernetes Manifests (`kubernetes/manifests/nexus/`)

### Core Manifests

| File                           | Function                                                              |
| ------------------------------ | --------------------------------------------------------------------- |
| **`namespace.yaml`**           | Creates `coordination-system` namespace with labels                   |
| **`serviceaccount.yaml`**      | Service account with IRSA annotations for AWS access                  |
| **`configmap.yaml`**           | Application configuration (ports, consensus, timeouts, features)      |
| **`secret.yaml`**              | Secret template for DB credentials, TLS certs, API keys               |
| **`statefulset.yaml`**         | 3-replica StatefulSet with init containers, probes, security contexts |
| **`service.yaml`**             | Three services: headless, API (8080), consensus (9090)                |
| **`poddisruptionbudget.yaml`** | PDB to maintain quorum (minAvailable: 2)                              |
| **`networkpolicy.yaml`**       | Network isolation rules for ingress/egress traffic                    |
| **`servicemonitor.yaml`**      | Prometheus ServiceMonitor for metrics scraping (9091)                 |
| **`ingress.yaml`**             | AWS ALB Ingress for external API access (public + internal)           |
| **`kustomization.yaml`**       | Kustomize configuration for all manifests                             |
| **`README.md`**                | Deployment guide for raw manifests                                    |

### Key Resources Created

- **Pods**: `nexus-cluster-0`, `nexus-cluster-1`, `nexus-cluster-2`
- **PVCs**: 20Gi gp3 volumes per pod
- **Services**: API endpoint, headless service, consensus communication
- **Ingress**: External access via AWS Application Load Balancer

## 📦 Helm Chart (`kubernetes/helm/charts/nexus/`)

### Chart Files

| File              | Function                                                 |
| ----------------- | -------------------------------------------------------- |
| **`Chart.yaml`**  | Chart metadata (name, version, description, maintainers) |
| **`values.yaml`** | Default configuration values (342 lines of options)      |
| **`README.md`**   | Helm chart usage guide with examples                     |

### Templates (`kubernetes/helm/charts/nexus/templates/`)

| File                           | Function                                                  |
| ------------------------------ | --------------------------------------------------------- |
| **`_helpers.tpl`**             | Template helper functions for names, labels, namespaces   |
| **`statefulset.yaml`**         | Templated StatefulSet with all configurations             |
| **`service.yaml`**             | Templated services (headless, API, consensus)             |
| **`serviceaccount.yaml`**      | Templated service account with IRSA                       |
| **`configmap.yaml`**           | Templated ConfigMap from values                           |
| **`secret.yaml`**              | Templated Secret (or External Secrets integration)        |
| **`ingress.yaml`**             | Templated Ingress for external access                     |
| **`poddisruptionbudget.yaml`** | Templated PDB for high availability                       |
| **`servicemonitor.yaml`**      | Templated Prometheus ServiceMonitor                       |
| **`NOTES.txt`**                | Post-installation instructions shown after `helm install` |

### Key Features

- **Parameterized**: All values configurable via `values.yaml`
- **Production-ready**: Security contexts, probes, resource limits
- **Flexible**: Supports external secrets, custom domains, TLS
- **Observable**: Built-in Prometheus integration

## 🤖 Automation Scripts (`scripts/`)

| File                   | Function                                                          |
| ---------------------- | ----------------------------------------------------------------- |
| **`deploy-nexus.sh`**  | Automated deployment script - Terraform → kubectl → Helm          |
| **`destroy-nexus.sh`** | Safe cleanup script with confirmations and RDS protection removal |

### Script Features

- **`deploy-nexus.sh`**:

  - Prerequisites checking (aws, terraform, kubectl, helm, jq)
  - Terraform infrastructure deployment
  - kubectl configuration
  - RDS credentials retrieval from Secrets Manager
  - Helm chart deployment with auto-configured values
  - Health checks and verification
  - Dry-run mode support

- **`destroy-nexus.sh`**:
  - Helm release uninstallation
  - PVC cleanup
  - Namespace deletion
  - RDS deletion protection removal
  - Terraform infrastructure destruction
  - Multiple confirmation prompts for safety

## 🏗️ Resource Hierarchy

```
Terraform (Infrastructure Layer)
├── VPC + Networking
├── EKS Cluster
├── RDS PostgreSQL
├── KMS Keys
├── IAM Roles
└── Creates K8s Namespace + ServiceAccount
    ↓
Kubernetes/Helm (Application Layer)
├── StatefulSet (3 replicas)
│   ├── Pod: nexus-cluster-0
│   ├── Pod: nexus-cluster-1
│   └── Pod: nexus-cluster-2
├── Services
│   ├── nexus-headless (StatefulSet DNS)
│   ├── nexus-api (ClusterIP for API)
│   └── nexus-consensus (Inter-pod communication)
├── PVCs (20Gi each, gp3)
├── Ingress (ALB for external access)
└── Monitoring (ServiceMonitor for Prometheus)
```

## 🔑 Key Configuration Files

### Most Important Files to Review

1. **`terraform/envs/nexus/terraform.tfvars`**

   - Set your environment-specific values
   - Instance types, sizes, regions

2. **`kubernetes/helm/charts/nexus/values.yaml`**

   - Application configuration
   - Resource limits, replicas, ingress settings

3. **`terraform/envs/nexus/main.tf`**

   - Infrastructure definition
   - Database, cluster, security configuration

4. **`kubernetes/manifests/nexus/statefulset.yaml`**
   - Pod specification
   - Container config, volumes, probes

## 📊 File Statistics

| Category          | Count | Total Lines |
| ----------------- | ----- | ----------- |
| **Documentation** | 5     | ~3,000      |
| **Terraform**     | 8     | ~800        |
| **K8s Manifests** | 12    | ~1,200      |
| **Helm Chart**    | 11    | ~1,500      |
| **Scripts**       | 2     | ~600        |
| **Total**         | 38    | ~7,100      |

## 🎯 Deployment Flow

```
1. Review & Configure
   ├── terraform/envs/nexus/terraform.tfvars
   └── kubernetes/helm/charts/nexus/values.yaml

2. Deploy Infrastructure
   └── scripts/deploy-nexus.sh
       ├── Runs: terraform apply
       ├── Configures: kubectl
       ├── Retrieves: RDS credentials
       └── Deploys: Helm chart

3. Verify Deployment
   ├── kubectl get all -n coordination-system
   ├── kubectl logs -f statefulset/nexus-cluster
   └── kubectl port-forward svc/nexus-api 8080:8080

4. Cleanup (when needed)
   └── scripts/destroy-nexus.sh
```

## 🔍 Quick File Lookup

**Need to change...**

| What                  | Where                                                           |
| --------------------- | --------------------------------------------------------------- |
| **Cluster size**      | `terraform/envs/nexus/terraform.tfvars` (eks_node_desired_size) |
| **Replica count**     | `kubernetes/helm/charts/nexus/values.yaml` (replicaCount)       |
| **Database size**     | `terraform/envs/nexus/terraform.tfvars` (rds_instance_class)    |
| **Domain name**       | `kubernetes/helm/charts/nexus/values.yaml` (ingress.hosts)      |
| **Resource limits**   | `kubernetes/helm/charts/nexus/values.yaml` (resources)          |
| **Container image**   | `kubernetes/helm/charts/nexus/values.yaml` (image.repository)   |
| **AWS region**        | `terraform/envs/nexus/terraform.tfvars` (aws_region)            |
| **Security policies** | `kubernetes/manifests/nexus/networkpolicy.yaml`                 |
| **Monitoring**        | `kubernetes/manifests/nexus/servicemonitor.yaml`                |
| **Environment vars**  | `kubernetes/helm/charts/nexus/values.yaml` (config section)     |

## 📖 Documentation Reading Order

For new users, read in this order:

1. **`docs/nexus-architecture.md`** - Understand the system
2. **`terraform/envs/nexus/README.md`** - Infrastructure overview
3. **`docs/nexus-deployment-guide.md`** - Step-by-step deployment
4. **`docs/nexus-quick-reference.md`** - Daily operations
5. **`kubernetes/helm/charts/nexus/README.md`** - Helm chart details

## 🚀 Quick Start Files

**Minimum files needed to deploy:**

```bash
# Must configure these:
terraform/envs/nexus/terraform.tfvars
kubernetes/helm/charts/nexus/values.yaml

# Then run:
scripts/deploy-nexus.sh
```

---

**Total**: 38 files across 5 categories, ~7,100 lines of production-ready infrastructure code.
