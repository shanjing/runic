# Nexus Helm Chart

A Helm chart for deploying **Nexus** - a production-grade stateful coordination service for blockchain and distributed systems.

## About Nexus

> **Note**: This project is purely for fun and experimentation—exploring how to scale Kubernetes to support low-latency stateful applications with production-grade infrastructure patterns.

Nexus is a cryptographic coordination layer that manages off-chain state transitions in distributed blockchain systems. It provides:

- **State Coordination**: Manages off-chain ledger of states with secure key rotations
- **High Availability**: 3-replica StatefulSet with Raft/Tendermint consensus for fault tolerance
- **Persistent Storage**: Each replica maintains its own state with automatic failover
- **Security**: Integrated with AWS KMS, IRSA, network policies, and pod security contexts
- **Monitoring**: Built-in Prometheus metrics and health checks
- **Scalability**: Auto-scaling support with configurable resource limits

**Key Use Cases:**

- Off-chain state coordination for blockchain applications
- Secure multi-party key management and rotation
- High-throughput transaction coordination
- Distributed consensus for state transitions in payment networks

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- PV provisioner support in the underlying infrastructure (e.g., EBS CSI driver on AWS)
- PostgreSQL database (RDS or similar)

## Installing the Chart

### Install from Local Repository

**Recommended for initial setup:**

```bash
# Clone the repository
git clone https://github.com/shanjing/runic.git
cd runic

# Install from repository path
helm install nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --create-namespace

# Or with custom values
helm install nexus ./kubernetes/helm/charts/nexus \
  -n coordination-system \
  --create-namespace \
  -f my-values.yaml
```

### Install from Helm Repository (Future)

```bash
# Add the helm repository (once published)
helm repo add nexus https://charts.example.com/nexus
helm repo update

# Install the chart
helm install nexus nexus/nexus -n coordination-system --create-namespace
```

### Install from Current Directory

If you're already in the chart directory:

```bash
# Navigate to chart directory
cd kubernetes/helm/charts/nexus

# Install from local directory
helm install nexus . -n coordination-system --create-namespace

# Install with custom values
helm install nexus . -n coordination-system --create-namespace -f values-production.yaml
```

### Install with Custom Values

```bash
helm install nexus . -n coordination-system --create-namespace \
  --set replicaCount=5 \
  --set image.tag=v1.0.0 \
  --set secrets.database.host=my-rds.us-west-2.rds.amazonaws.com \
  --set secrets.database.password=mysecretpassword
```

## Uninstalling the Chart

```bash
# Uninstall the release
helm uninstall nexus -n coordination-system

# Delete PVCs (they are not deleted automatically)
kubectl delete pvc -n coordination-system -l app.kubernetes.io/name=nexus
```

## Configuration

The following table lists the configurable parameters of the Nexus chart and their default values.

### Global Settings

| Parameter            | Description              | Default      |
| -------------------- | ------------------------ | ------------ |
| `global.environment` | Environment name         | `production` |
| `replicaCount`       | Number of replicas       | `3`          |
| `nameOverride`       | Override chart name      | `""`         |
| `fullnameOverride`   | Override full chart name | `""`         |

### Image Settings

| Parameter          | Description       | Default        |
| ------------------ | ----------------- | -------------- |
| `image.repository` | Image repository  | `runic/nexus`  |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag`        | Image tag         | `latest`       |

### Service Account

| Parameter                    | Description                 | Default                 |
| ---------------------------- | --------------------------- | ----------------------- |
| `serviceAccount.create`      | Create service account      | `true`                  |
| `serviceAccount.annotations` | Service account annotations | `{}`                    |
| `serviceAccount.name`        | Service account name        | `nexus-service-account` |

### Service Configuration

| Parameter                | Description    | Default     |
| ------------------------ | -------------- | ----------- |
| `service.type`           | Service type   | `ClusterIP` |
| `service.api.port`       | API port       | `8080`      |
| `service.consensus.port` | Consensus port | `9090`      |
| `service.metrics.port`   | Metrics port   | `9091`      |

### Ingress Configuration

| Parameter           | Description        | Default           |
| ------------------- | ------------------ | ----------------- |
| `ingress.enabled`   | Enable ingress     | `true`            |
| `ingress.className` | Ingress class name | `alb`             |
| `ingress.hosts`     | Ingress hosts      | See `values.yaml` |

### Resources

| Parameter                   | Description    | Default |
| --------------------------- | -------------- | ------- |
| `resources.requests.cpu`    | CPU request    | `500m`  |
| `resources.requests.memory` | Memory request | `1Gi`   |
| `resources.limits.cpu`      | CPU limit      | `2000m` |
| `resources.limits.memory`   | Memory limit   | `4Gi`   |

### Persistence

| Parameter                      | Description        | Default |
| ------------------------------ | ------------------ | ------- |
| `persistence.enabled`          | Enable persistence | `true`  |
| `persistence.storageClassName` | Storage class      | `gp3`   |
| `persistence.size`             | Volume size        | `20Gi`  |

### Database Configuration

| Parameter                   | Description       | Default      |
| --------------------------- | ----------------- | ------------ |
| `secrets.database.host`     | Database host     | `""`         |
| `secrets.database.port`     | Database port     | `5432`       |
| `secrets.database.name`     | Database name     | `nexusdb`    |
| `secrets.database.user`     | Database user     | `nexusadmin` |
| `secrets.database.password` | Database password | `""`         |

### Monitoring

| Parameter                 | Description           | Default |
| ------------------------- | --------------------- | ------- |
| `serviceMonitor.enabled`  | Enable ServiceMonitor | `true`  |
| `serviceMonitor.interval` | Scrape interval       | `30s`   |

## Examples

### Production Deployment

Create a `values-production.yaml` file:

```yaml
replicaCount: 5

image:
  repository: ghcr.io/shanjing/nexus
  tag: v1.0.0
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    cpu: 4000m
    memory: 8Gi

persistence:
  storageClassName: io2
  size: 50Gi

secrets:
  database:
    host: nexus-prod.abc123.us-west-2.rds.amazonaws.com
    password: "YOUR_SECURE_PASSWORD"

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/nexus-prod-role

ingress:
  annotations:
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-west-2:123456789012:certificate/xxxxx
  hosts:
    - host: nexus-api.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
```

Deploy:

```bash
helm install nexus . -n coordination-system -f values-production.yaml
```

### Development Deployment

```bash
helm install nexus-dev . -n coordination-system-dev --create-namespace \
  --set replicaCount=1 \
  --set image.tag=dev \
  --set persistence.size=10Gi \
  --set resources.requests.cpu=250m \
  --set resources.requests.memory=512Mi
```

### Using External Secrets Operator

```yaml
externalSecrets:
  enabled: true
  secretStore:
    name: aws-secrets-manager
    kind: SecretStore
  refreshInterval: 1h
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: nexus-rds-credentials
        property: password
    - secretKey: DB_HOST
      remoteRef:
        key: nexus-rds-credentials
        property: host
```

## Upgrading

### Upgrade the Release

```bash
# Upgrade with new values
helm upgrade nexus . -n coordination-system -f values-production.yaml

# Upgrade with new image
helm upgrade nexus . -n coordination-system --set image.tag=v1.1.0

# Force upgrade (recreate pods)
helm upgrade nexus . -n coordination-system --force
```

### Rollback

```bash
# Rollback to previous release
helm rollback nexus -n coordination-system

# Rollback to specific revision
helm rollback nexus 2 -n coordination-system

# View rollback history
helm history nexus -n coordination-system
```

## Testing

### Helm Test

```bash
# Run helm tests (if test pods are defined)
helm test nexus -n coordination-system
```

### Template Validation

```bash
# Render templates locally
helm template nexus . -n coordination-system

# Render with specific values
helm template nexus . -n coordination-system -f values-production.yaml

# Validate against Kubernetes
helm template nexus . -n coordination-system | kubectl apply --dry-run=client -f -
```

### Lint

```bash
# Lint the chart
helm lint .

# Lint with values
helm lint . -f values-production.yaml
```

## Troubleshooting

### View Deployed Resources

```bash
# List all resources
helm get manifest nexus -n coordination-system

# Get values
helm get values nexus -n coordination-system

# Get full details
helm get all nexus -n coordination-system
```

### Debug Template Rendering

```bash
# Debug with --debug flag
helm install nexus . -n coordination-system --dry-run --debug

# Check specific template
helm template nexus . -s templates/statefulset.yaml
```

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl describe pod nexus-0 -n coordination-system

# Check events
kubectl get events -n coordination-system --sort-by='.lastTimestamp'
```

#### PVC Not Binding

```bash
# Check PVC status
kubectl get pvc -n coordination-system

# Check storage class
kubectl describe storageclass gp3
```

#### Database Connection Issues

```bash
# Verify secrets
kubectl get secret nexus-secrets -n coordination-system -o yaml

# Test connection from pod
kubectl exec -it nexus-0 -n coordination-system -- sh
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

## Contributing

Please read the main project documentation for contribution guidelines.

## License

See the LICENSE file in the main repository.
