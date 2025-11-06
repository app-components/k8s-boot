# ADR-010: Use Server-Side Apply (SSA) for All Bootstrap and Upgrade Operations

**Date:** 2025-11-06  
**Status:** Accepted  
**Deciders:** Platform Engineering  
**Context:** k8s-boot / k8s-core release pipeline  

## Context

`k8s-boot` produces large, monolithic YAML bundles (hundreds of objects across Flux CD, External Secrets Operator, RBAC, and supporting resources).  
These bundles are applied directly with `kubectl` during initial cluster bring-up and during upgrades between minor or patch releases.

The traditional `kubectl apply` performs **client-side diffing and merging**, which has several drawbacks:

- Large manifests can exceed local memory or CPU limits.  
- Client-side ordering cannot account for dynamic dependencies (e.g., CRDs → CR ordering).  
- Merge semantics differ across `kubectl` versions.  
- No built-in field ownership tracking or conflict detection.  

Kubernetes now provides **Server-Side Apply (SSA)**—a declarative merge engine that runs inside the API server and maintains authoritative “field ownership” metadata.  
Using SSA improves determinism, scale, and safety for large declarative bundles such as `bootstrap.yaml`.

## Decision

All `k8s-boot` and `k8s-core` manifests **must be applied using Server-Side Apply**.

The standard invocation pattern is:

```bash
kubectl apply \
  --server-side \
  --force-conflicts \
  --field-manager=k8s-boot \
  -f bootstrap.yaml
```

### Policy Statements

1. **SSA is mandatory** for every bootstrap, patch, or minor-line upgrade.  
2. The field manager must be set to `k8s-boot` or `k8s-core` to allow clear ownership audits.  
3. All release pipelines and automation scripts (`build.sh`, `upgrade.sh`) must emit SSA-compliant commands.  
4. Server-side apply is considered the *merge authority* for Layer 1 and Layer 2 resources; Flux and other controllers operate under separate field managers.

## Rationale

| Concern | Server-Side Apply Behavior | Benefit |
|----------|-----------------------------|----------|
| **Large manifests** | Objects are streamed to API server; merge logic runs centrally | Scales to hundreds of objects per apply |
| **Ordering & dependencies** | API server processes CRDs first and defers dependent CRs automatically | Reliable CRD bootstrap |
| **Drift detection** | SSA tracks field ownership (`managedFields`) | Safe, idempotent reconciliation |
| **Conflict resolution** | Raises 409 if another manager owns the same field | Prevents accidental overwrites |
| **Reproducibility** | Merge semantics defined in K8s API, not `kubectl` version | Consistent across clusters |
| **Auditability** | Ownership visible via `kubectl get -o jsonpath='{.metadata.managedFields}'` | Clear change attribution |

## Consequences

### Positive
- **Scalable Bootstrap** — Handles large monolithic YAMLs efficiently.  
- **Idempotent Upgrades** — Re-applying the same manifest safely merges changes.  
- **Safer Drift Correction** — Conflicts are explicit, not silently overwritten.  
- **Improved Auditability** — Ownership metadata aids troubleshooting and compliance.  
- **Simpler CI/CD** — No need to pre-split manifests or manage apply order manually.

### Negative
- Slightly larger `managedFields` metadata per resource (~2–5 KB).  
- Occasional merge conflicts when multiple field managers edit overlapping fields.  

### Mitigations
- Use dedicated field manager names per layer (`k8s-boot`, `k8s-core`, `platform-apps`).  
- For conflicts, rerun apply with `--force-conflicts` during controlled upgrades.  
- Periodically prune old `managedFields` entries via CI cleanup if necessary.

## Implementation Notes

- `build.sh` and upgrade pipelines embed the SSA flags automatically.  
- All bootstrap examples in READMEs use SSA by default.  
- CI smoke tests verify that re-applying the same bundle is a no-op (idempotent).  
- Documentation warns users **not** to mix `kubectl apply` (client-side) with SSA for the same objects.

## Alternatives Considered

| Option | Description | Outcome |
|---------|--------------|----------|
| **Client-side apply** | Default `kubectl apply` behavior. | Rejected — non-deterministic merge logic and ordering issues. |
| **kubectl replace** | Replace each resource wholesale. | Rejected — not idempotent, causes controller restarts. |
| **Flux self-bootstrap via GitOps** | Have Flux apply itself. | Rejected — creates circular dependency and race conditions. |

## References

- [Kubernetes Server-Side Apply Design Doc](https://kubernetes.io/docs/reference/using-api/server-side-apply/)  
- [kubectl apply CLI Reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#apply)  
- [ADR-002 Drift Guard Strategy](./0002-drift-guard-strategy.md)

# **Decision Summary:**  
All bootstrap and upgrade workflows in `k8s-boot` and `k8s-core` use **Server-Side Apply** as the canonical mechanism for applying resources.  
This ensures scalable, idempotent, and auditable reconciliation for large declarative Kubernetes bundles, aligning with the project’s goal of **“install once, reconcile forever.”**