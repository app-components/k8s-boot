# ADR-005: Choose FluxCD as the GitOps Engine

**Date:** 2025-11-06
**Status:** Accepted
**Context:** k8s-boot / Layer 1 design  

## Context

The `k8s-boot` project defines **Layer 1 – Bootstrap**, whose role is to transform a raw Kubernetes cluster into a **self-reconciling, GitOps-driven control plane**.

Several open-source options exist for GitOps orchestration:

- **FluxCD** (GitOps Toolkit controllers)  
- **Carvel kapp-controller**  
- **Argo CD**

We must choose an engine that is:

- **Declarative and composable** — built entirely on CRDs  
- **Lightweight and bootstrap-friendly** — no databases or web servers  
- **Deterministic and air-gap-compatible** — static manifests only  
- **UI-optional and automation-friendly** — works headlessly for CLI, API, or AI-agent control  
- **Auditable and future-proof** — traceable state through Git, not runtime secrets  

## Decision

Adopt **FluxCD** as the **GitOps engine** for Layer 1 (`k8s-boot`) and all higher layers.  
Only a **minimal subset** of controllers will be installed at bootstrap:

| Controller | Included | Purpose |
|-------------|-----------|----------|
| `source-controller` | ✅ | Fetches and caches manifests from Git or OCI sources |
| `kustomize-controller` | ✅ | Reconciles manifests declaratively via Kustomize |
| `notification-controller` | ✅ | Emits events and alerts between controllers |
| `helm-controller` | ❌ | Excluded – see [ADR-006](./006-disable-flux-helm-controller.md) |
| `image-reflector-controller` | ❌ | Excluded – mutable automation |
| `image-automation-controller` | ❌ | Excluded – auto-committing image updates |

Flux in `k8s-boot` therefore performs only **declarative source + apply** operations—no runtime mutation or templating.

## Rationale

### Why FluxCD

| Requirement | Flux Capability | Outcome |
|--------------|----------------|----------|
| **Native CRD model** | Controllers expose typed Kubernetes APIs | Integrates naturally into Layer 1 bootstrap |
| **Composable architecture** | Each controller operates independently | Minimal, failure-isolated footprint |
| **OCI + Git sources** | Source Controller supports both | Works in connected or air-gapped clusters |
| **Notifications** | Built-in Notification Controller | Native eventing / alerting pipeline |
| **Headless by design (No UI)** | Flux has no built-in web interface | Simplifies the system, avoids opinionated UIs, and enables AI agents / CLI automation to drive operations directly |

### Why not Carvel kapp-controller
- kapp-controller has a smaller community and ecosystem compared to FluxCD.  
- Lacks a native equivalent to Flux’s **Notification Controller**, reducing platform observability.  

### Why not Argo CD
- The mandatory UI conflicts with the design goal of a **text-first, automation-oriented control plane**. 
- Monolithic architecture, not easily decomposed into independently upgradeable controllers.  

## Consequences

### Positive
- **Small, stable bootstrap footprint** – three controllers only  
- **Predictable and auditable** – all behavior declarative and Git-visible  
- **UI-free and automation-ready** – integrates cleanly with CLI tools and AI agents  
- **Supports drift-guard and layered upgrades**  
- **First-class notifications** – unified event stream across layers  

### Negative
- No automatic image or Helm-based updates (intentional design choice)  
- Slightly more YAML (explicit `GitRepository` + `Kustomization` objects per layer)

## 5  Implementation Notes

- Layer 1 installs:
  - Deployments for `source-controller`, `kustomize-controller`, `notification-controller`
  - Associated RBAC and ServiceAccounts in `flux-system`
- Other Flux controllers removed from bundle  
- Drift-guard (`GitRepository` + `Kustomization`) points to `k8s-boot` repo  
- Higher layers (`k8s-core`, applications) reuse these controllers with their own sources  

## 6  Alternatives Considered

| Option | Description | Outcome |
|---------|--------------|----------|
| **FluxCD (full suite)** | Include Helm and Image controllers | Rejected – adds mutable, runtime behavior |
| **Carvel kapp-controller** | Lightweight GitOps operator from VMware Carvel suite | Rejected – smaller community, no notification system |
| **Argo CD** | Monolithic GitOps platform with UI and API server | Rejected – heavier architecture and UI-centric model |

## 7  References

- [FluxCD Documentation](https://fluxcd.io/docs/)  
- [Carvel kapp-controller](https://carvel.dev/kapp-controller/)  
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)  
- [GitOps Toolkit Architecture](https://fluxcd.io/flux/concepts/)  
- [ADR-001 Layered Platform Model](./001-layered-platform.md)
- [ADR-006 Disable Flux Helm Controller](./006-disable-flux-helm-controller.md)
- [ADR-010 Always Use Server-Side Apply](./010-always-use-server-side-apply.md)  

**Decision Summary:**  
Adopt **FluxCD** as the GitOps engine across all layers, limited in `k8s-boot` to `source-controller`, `kustomize-controller`, and `notification-controller`.  
Reject Carvel kapp-controller and Argo CD due to smaller ecosystems and UI-centric architectures.  
A UI-free, CLI-first approach ensures simplicity, accessibility for AI automation, and a truly declarative GitOps foundation.
