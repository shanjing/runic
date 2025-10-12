# Nexus Helm Chart – Security Notes

This document captures the pod-level hardening choices baked into the Nexus chart. Network-layer controls will be documented alongside these notes once finalized.

## Pod Identity

- Pods run under a dedicated service account.
- `automountServiceAccountToken` is disabled by default so workload pods do not automatically receive Kubernetes API credentials.
- Provide a custom service account or enable token mounting only when the workload genuinely needs API access.

## Runtime Restrictions

- Pod-level `securityContext` enforces `runAsNonRoot`, drops all Linux capabilities, disallows privilege escalation, and enables the `RuntimeDefault` seccomp profile.
- Container filesystem is read-only; writable paths must be explicitly backed by volumes (e.g., the `data` PVC).
- The `wait-for-db` init container inherits a least-privilege security context using the same principles as the main container.

## Secrets & Configuration

- Sensitive values such as database credentials and encryption keys are sourced from Kubernetes Secrets.
- Configuration data is injected via ConfigMaps, keeping application configuration out of the container image.

## Persistence

- Each replica receives its own PersistentVolumeClaim through the StatefulSet’s `volumeClaimTemplates`, ensuring storage isolation per pod.
- The default storage class is `gp3`; adjust in `values.yaml` to align with your latency and durability requirements.

---

Future additions (network policies, service mesh policy, mTLS enforcement, etc.) will be appended here as they are implemented. Feel free to extend this guidance with any organization-specific guardrails.***
