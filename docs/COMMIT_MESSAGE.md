# Commit Message

## Title

Add Nexus - Stateful Coordination Service for Blockchain Systems

## Description

This commit introduces **Nexus**, a production-grade stateful coordination service designed for blockchain and distributed systems, featuring:

### Architecture

- **High Availability**: 3-replica StatefulSet with Raft/Tendermint consensus
- **Persistent Storage**: PVCs with gp3 EBS volumes
- **Database Backend**: RDS PostgreSQL Multi-AZ for state ledger
- **Security**: AWS KMS encryption, IRSA, network policies, pod security contexts
- **Monitoring**: Prometheus ServiceMonitor, Grafana dashboards, comprehensive logging

### Infrastructure Components

- **EKS Cluster**: Kubernetes 1.28 with auto-scaling (3-10 nodes)
- **VPC**: Multi-AZ setup with public/private subnets across 3 availability zones
- **Load Balancing**: AWS ALB with health checks and TLS support
- **Secrets Management**: AWS Secrets Manager integration
- **Cost Optimized**: ~$670/month baseline (us-west-2)

### Deployment Options

1. **Terraform**: Complete infrastructure-as-code in `terraform/envs/nexus/`
2. **Helm Chart**: Production-ready chart in `kubernetes/helm/charts/nexus/`
3. **Raw Manifests**: K8s manifests in `kubernetes/manifests/nexus/`
4. **Automation Scripts**: One-command deploy/destroy scripts

### Use Cases

- Off-chain state coordination for blockchain applications
- Secure multi-party key management
- High-throughput transaction coordination
- Distributed consensus for state transitions

### Documentation

- Architecture guide: `docs/nexus-architecture.md`
- Deployment guide: `docs/nexus-deployment-guide.md`
- Quick reference: `docs/nexus-quick-reference.md`
- Rename summary: `docs/NEXUS_RENAME.md`

### Repository

- Home: https://github.com/shanjing/runic
- Container Registry: ghcr.io/shanjing/nexus
- Maintainer: Shanjing

### Files Added

- 70+ new files across Terraform, Kubernetes, Helm, and documentation
- Comprehensive configuration with production-ready defaults
- Security best practices implemented throughout

### Technical Stack

- **Infrastructure**: Terraform + AWS (EKS, RDS, KMS, Secrets Manager)
- **Orchestration**: Kubernetes 1.28 with StatefulSets
- **Package Management**: Helm 3
- **Database**: PostgreSQL 15.4 (Multi-AZ)
- **Monitoring**: Prometheus Operator + Grafana
- **Security**: IRSA, KMS, Network Policies, Pod Security Standards

---

Ready for production deployment with comprehensive documentation and automation.
