# ADR-007: Drift Guard Strategy for Layer 1 (Flux + ESO)

**Date:** 2025-11-06
**Status:** Accepted
**Context:** k8s-boot / Layer 1 design  

## Context

The `k8s-boot` project provides a single `kubectl apply` bootstrap that installs **FluxCD** and **External Secrets Operator (ESO)** as the Layer 1 foundation of a Kubernetes cluster.

Once installed, Flux must **continuously reconcile its own manifests** to prevent manual drift (e.g., users editing controller Deployments or RBAC).  
To achieve this, `k8s-boot` needs a *drift guard* — a `GitRepository` + `Kustomization` pair that points back to the canonical Layer 1 manifests.

Several competing patterns exist:

| Option | Description | Upgrade mechanism |
|---------|--------------|-------------------|
| **A. Immutable self-guard** | Drift guard lives inside `k8s-boot`.  Clusters upgrade only when operators apply a new bootstrap YAML. | `kubectl apply -f bootstrap-1.0.3.yaml` |
| **B. Delegated guard** | Drift guard lives in a separate “cluster” or “platform-bootstrap” repo that references `k8s-boot`. | GitOps (Flux updates itself) |
| **C. Hybrid minor-line tracking** | Drift guard lives inside `k8s-boot`, but clusters track the latest patch via a moving file such as `bootstrap-1.0.x.yaml`. | Periodic or manual `kubectl apply -f bootstrap-1.0.x.yaml` |

## Decision

`k8s-boot` will implement **Option C — the hybrid minor-line tracking model**.

### Key characteristics

1. **Self-contained drift guard**  
   - The `GitRepository` and `Kustomization` are bundled in every `bootstrap-*.yaml`.  
   - They point back to the `src/<minor>` directory within the same repository.

2. **Minor-line patch tracking**  
   - Each minor line publishes immutable patch files (`bootstrap-1.0.1.yaml`, `bootstrap-1.0.2.yaml`, …)  
     plus a mutable tracking file (`bootstrap-1.0.x.yaml`) that always references the latest patch.  
   - Operators apply the tracking file:
     ```bash
     kubectl apply --server-side \
       -f https://raw.githubusercontent.com/app-components/k8s-boot/main/release/1.0/bootstrap-1.0.x.yaml
     ```
   - When a new patch is released, re-applying the same URL brings clusters up-to-date.

3. **Explicit minor/major upgrades**  
   - Clusters never cross a minor boundary automatically.  
   - Upgrading from 1.0 → 1.1 requires an explicit human or pipeline action.

4. **Server-side apply**  
   - All bootstrap operations use `--server-side --force-conflicts` for idempotent, CRD-aware reconciliation.

## Rationale

### Why not immutable only (Option A)?
- Requiring a manual `kubectl apply` for every patch would make routine security updates operationally heavy.  
- Minor-line tracking allows safe automation of patch upgrades without loss of control.

### Why not delegated (Option B)?
- Delegated GitOps adds indirection and another repository to maintain.  
- Layer 1 must remain minimal, reproducible, and auditable — not self-mutating via Git.  
- Higher layers (e.g., `k8s-core`) will already use GitOps for continuous delivery; Layer 1 should stay deterministic.

### Why the hybrid model?
- Balances **stability** (no implicit minor jumps) with **maintainability** (auto-patched within a minor).  
- Works offline or air-gapped since the applied file contains all manifests.  
- Keeps the operational surface area small: one repo, one YAML.

## Consequences

### Positive
- **Self-healing baseline** — Flux and ESO continuously reconcile their definitions.  
- **Simple upgrade path** — `kubectl apply` of a stable URL picks up all latest patches.  
- **Predictable versioning** — only manual action can change minor or major versions.  
- **Auditable releases** — each patch has its own immutable artifact and changelog.

### Negative
- Requires maintainers to keep the tracking file (`bootstrap-1.0.x.yaml`) updated.  
- Clusters that never re-apply the tracking URL won’t automatically receive patch updates.  
- Still one manual step when crossing minor or major versions.


## Example Implementation

```yaml
# Embedded drift guard inside bootstrap bundle
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: k8s-boot
  namespace: flux-system
spec:
  interval: 5m
  url: https://github.com/app-components/k8s-boot
  ref:
    branch: main
  ignore: |
    /*
    !/src/1.0/
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: k8s-boot-layer1
  namespace: flux-system
spec:
  interval: 10m
  path: ./src/1.0
  sourceRef:
    kind: GitRepository
    name: k8s-boot
  prune: true
  wait: true
  force: true
```

## Upgrade Flow Summary

| Action | Trigger | Result |
|---------|----------|--------|
| **Patch release** | Maintainer publishes `bootstrap-1.0.3.yaml` and refreshes `bootstrap-1.0.x.yaml` | Cluster reconciles to new patch after next apply or Flux sync |
| **Minor release** | New `bootstrap-1.1.0.yaml` published | Operator explicitly switches applied URL |
| **Major release** | Breaking change | Manual upgrade, possibly migration guide |

