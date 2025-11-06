# ADR-002: Bootstrap Philosophy and Scope

**Date:** 2025-11-06
**Status:** Accepted
**Context:** k8s-boot / Layer 1 design

## Context

The **k8s-boot** project defines *Layer 1 – Bootstrap* in the four-layer Kubernetes model (see ADR-001).  
This layer is responsible for transforming an empty Kubernetes cluster into a self-managing, GitOps-enabled system.

Historically, bootstrap systems tend to grow unchecked—adding ingress, observability, metrics, or build automation until the “foundation” becomes a miniature platform of its own.  
To keep clusters deterministic and maintainable, k8s-boot must remain **small, predictable, and self-contained**.

This ADR records the explicit **philosophy and scope boundaries** for Layer 1 so future contributors cannot accidentally expand it.

## Decision

### Intent
Layer 1 exists **only** to:
1. Establish a reproducible GitOps control plane.  
2. Provide a secure mechanism to materialize secrets from external vaults.  

Once those two capabilities exist, the cluster can manage everything else declaratively.

### Included Components
| Category | Component | Purpose |
|-----------|------------|----------|
| **GitOps Engine** | **FluxCD** (Source, Kustomize, Notification Controllers) | Reconcile YAML from Git or OCI sources and emit status events. |
| **Secret Management** | **External Secrets Operator (ESO)** | Synchronize credentials from external backends (1Password, Vault, AWS SM, etc.). |

These are the **only controllers** installed by k8s-boot.  
They form the minimal control plane required for higher-level layers to function.

### Explicit Exclusions
| Excluded Area | Rationale |
|----------------|------------|
| **Helm Controller** | Introduces runtime templating and dependency ordering (see ADR-006). |
| **Image Automation Controllers** | Mutable state; violates declarative immutability of Layer 1. |
| **Ingress, DNS, Cert-Management, Metrics** | Belong to Layer 2 (k8s-core) where platform policy is defined. |
| **UI or Dashboard Components** | Not required; automation and AI agents interact via CLI / API. |

### Operational Constraints
- **Single-step install:** one `kubectl apply --server-side` command.  
- **Offline-ready:** no network fetches; all artifacts vendored.  
- **Self-healing:** Flux reconciles its own manifests for drift.  
- **Time-to-readiness:** controllers running within ≈ 60 seconds on a fresh cluster.  
- **No secrets in Git:** only `ExternalSecret` CRs and backend references are committed.

### Design Philosophy
- **Small and boring:** minimize moving parts to maximize reliability.  
- **Deterministic:** identical result across clusters and environments.  
- **CLI / API first:** no built-in UI; textual workflows are easier to automate and integrate with AI agents.  
- **Composable:** higher layers can add capabilities without modifying Layer 1.  
- **Immutable:** upgrades occur only via new versioned bootstrap artifacts.

## Rationale

1. Keeping Layer 1 minimal ensures fast, reliable cluster bring-up and clear separation of concerns.  
2. GitOps + secrets sync are universal requirements; everything else is optional or environment-specific.  
3. A deterministic bootstrap simplifies audits, air-gapped operation, and disaster recovery.  
4. The absence of a UI eliminates opinionated interfaces and aligns with automation-first workflows.  

## Consequences

### Positive
- Extremely fast and reproducible cluster bootstraps.  
- Minimal surface for drift, upgrades, and CVEs.  
- Works identically online or air-gapped.  
- Clean boundaries between bootstrap (k8s-boot) and platform (k8s-core).  

### Negative
- Requires a second Layer 2 install for ingress, cert-manager, observability, etc.  
- May feel “too bare” for new users expecting a full platform out-of-the-box.  
- Slightly more manual setup for initial secret backend configuration.  

## Alternatives Considered

| Option | Description | Outcome |
|---------|--------------|----------|
| **Monolithic Bootstrap** | Include ingress, cert-manager, metrics, etc. | Rejected – bloats Layer 1 and slows startup. |
| **Dynamic Helm-based Bootstrap** | Use Helm Controller to install Flux/ESO. | Rejected – runtime templating, CRD ordering issues. |
| **Custom Operator** | Write a bespoke bootstrap controller. | Rejected – unnecessary; Flux + SSA already provide desired behavior. |

## References
- [ADR-001 Layered Platform Model](./001-layered-platform.md)
- [ADR-006 Disable Flux Helm Controller](./006-disable-flux-helm-controller.md)
- [ADR-008 Choose External Secrets Operator](./008-choose-external-secrets-operator.md)
- [ADR-010 Always Use Server-Side Apply](./010-always-use-server-side-apply.md)  
- [Flux Documentation](https://fluxcd.io/docs/)  
- [External Secrets Operator](https://external-secrets.io/)  

**Decision Summary:**  
Layer 1 (k8s-boot) is the smallest possible bootstrap:  
Flux (Source + Kustomize + Notification) + External Secrets Operator — nothing else.  
It exists solely to give the cluster a GitOps control plane and a secure secret-sync mechanism.  
All additional functionality must live in higher layers.
