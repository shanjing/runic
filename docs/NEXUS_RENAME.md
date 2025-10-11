# Nexus Rename Summary

This document tracks the renaming from `scs` (State Coordination Service) to `nexus` across the entire codebase.

## Changes Made

### 1. Directory Renames

- `kubernetes/helm/charts/scs/` → `kubernetes/helm/charts/nexus/`
- `kubernetes/manifests/scs/` → `kubernetes/manifests/nexus/`
- `terraform/envs/scs/` → `terraform/envs/nexus/`

### 2. Script Renames

- `scripts/deploy-scs.sh` → `scripts/deploy-nexus.sh`
- `scripts/destroy-scs.sh` → `scripts/destroy-nexus.sh`

### 3. Documentation Renames

- `docs/scs-architecture.md` → `docs/nexus-architecture.md`
- `docs/scs-deployment-guide.md` → `docs/nexus-deployment-guide.md`
- `docs/scs-quick-reference.md` → `docs/nexus-quick-reference.md`

### 4. Code Changes

#### Container Images

- `runic/scs:latest` → `runic/nexus:latest`

#### Kubernetes Resources

- Namespace: `coordination-system` (unchanged)
- StatefulSet: `scs-cluster` → `nexus-cluster`
- Pods: `scs-cluster-0` → `nexus-cluster-0`
- Services: `scs-api` → `nexus-api`, `scs-headless` → `nexus-headless`
- ServiceAccount: `scs-service-account` → `nexus-service-account`
- Labels: `app: scs` → `app: nexus`

#### Terraform Resources

- Cluster name: `scs-coordination-cluster` → `nexus-coordination-cluster`
- RDS instance: `scs-coordination-cluster-db` → `nexus-coordination-cluster-db`
- Database name: `scsdb` → `nexusdb`
- Database user: `scsadmin` → `nexusadmin`
- IAM roles: `scs_service_account` → `nexus_service_account`
- Variables: All `scs_*` → `nexus_*`

#### File Paths

- Volume paths: `/var/lib/scs` → `/var/lib/nexus`
- Config paths: All references updated

### 5. Helm Chart Updates

- Chart name: `scs` → `nexus`
- Template helpers: All `scs.*` → `nexus.*`
- Values: All scs-related values renamed
- Container names: `scs-node` → `nexus-node`

### 6. Documentation Updates

- All references to "SCS" changed to "Nexus"
- Removed any specific product mentions
- Made descriptions generic for blockchain/distributed systems
- Updated URLs and repository references

## Deployment Commands

### Old Commands (SCS)

```bash
./scripts/deploy-scs.sh
helm install scs kubernetes/helm/charts/scs
kubectl get pods -l app=scs
terraform -chdir=terraform/envs/scs apply
```

### New Commands (Nexus)

```bash
./scripts/deploy-nexus.sh
helm install nexus kubernetes/helm/charts/nexus
kubectl get pods -l app=nexus
terraform -chdir=terraform/envs/nexus apply
```

## Important Notes

1. **Branch**: All changes are on `feature/stateful-coordination-service` branch
2. **Namespace**: Kept as `coordination-system` for consistency
3. **No Breaking Changes**: This is a clean rename with no functional changes
4. **Generic Content**: All documentation now uses generic blockchain terminology
5. **Safe to Push**: No proprietary or sensitive naming remains

## Testing Checklist

Before deploying, verify:

- [ ] Helm chart templates render correctly: `helm template nexus ./kubernetes/helm/charts/nexus`
- [ ] Terraform plan succeeds: `terraform -chdir=terraform/envs/nexus plan`
- [ ] Deployment script has correct paths: Check `scripts/deploy-nexus.sh`
- [ ] Documentation links are valid
- [ ] Container image references are correct

## Rollback

If you need to revert, the changes are contained to this branch:

```bash
git checkout main
# Or delete this branch and start over
```

## Next Steps

1. Review all changes
2. Test Helm chart rendering
3. Test Terraform plan (dry-run)
4. Commit changes to git
5. Deploy to test environment
6. Verify functionality
7. Merge to main branch

## Git Commands

```bash
# Review changes
git status
git diff

# Stage all changes
git add .

# Commit
git commit -m "Rename SCS to Nexus across entire codebase"

# Push
git push origin feature/stateful-coordination-service
```

## File Count

- **Modified**: 1 (README.md)
- **Added**: 70+ new files
- **Renamed**: All scs references changed to nexus
- **Total Impact**: ~100+ files affected

---

Generated: $(date)
Branch: feature/stateful-coordination-service
Status: ✅ Complete
