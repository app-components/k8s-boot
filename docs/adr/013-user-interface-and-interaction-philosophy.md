# ADR-013: User Interface and Interaction Philosophy

**Date:** 2025-11-06
**Status:** Accepted
**Context:** k8s-boot / platform architecture

## Context

Many Kubernetes platforms attempt to provide a unified web or GUI experience for all personas (developers, platform engineers, operators).  
While visually appealing, these UIs often:

- Add hidden logic layers between users and the actual cluster state.  
- Become opinionated or brittle as APIs evolve.  
- Fragment along team boundaries (one UI for DevOps, another for developers).  
- Create maintenance overhead and security concerns.  

`k8s-boot` and its downstream layers are deliberately **UI-agnostic**.  
They expose only the canonical Kubernetes and GitOps interfaces.  
This ensures interoperability with the broader ecosystem and allows each user persona to adopt their preferred experience.


## Decision

We will **not ship or depend on any built-in UI component** (web, desktop, or custom dashboard) as part of `k8s-boot` or `k8s-core`.  

Instead, the platform will rely exclusively on **standard APIs and CLI-friendly interfaces**:  

| Category | Interface |
|-----------|------------|
| Cluster management | `kubectl`, `flux`, `esoctl` |
| Observability | `kubectl get`, `kubectl logs`, `kubectl describe` |
| GitOps status | Flux Notification events |
| Secrets management | ESO CRDs and standard `Secret` objects |
| Network / ingress | Envoy Gateway CRDs and metrics |

This approach is fully compatible with modern, community-maintained tools such as:

- **k9s** — a fast, terminal UI for live cluster exploration and resource management.  
- **Headlamp** — a CNCF project offering an extensible GUI that runs both in the browser and as a desktop app.  
  - Supports plugins and extensions for custom workflows.  
  - Connects directly to any Kubernetes API server, no extra components needed.  
- **Lens** and **OpenLens** — alternative desktop GUIs for multi-cluster environments.  
- **Kubernetes Dashboard** — optional lightweight web interface.  

**k9s and Headlamp** are excellent options for teams seeking a rich experience without leaving the standard Kubernetes ecosystem.

## Rationale

1. **Standard interfaces, infinite UIs**  
   The Kubernetes API is the contract; any UI can layer on top.  
   Avoids building or maintaining bespoke dashboards.  

2. **Persona-specific experiences**  
   Developers, SREs, and security teams prefer different tools.  
   Each persona selects the UI—CLI, TUI, or GUI—that best fits their workflow.  

3. **Automation and AI readiness**  
   Text-based, API-driven systems are easy for AI agents and automation pipelines to interact with.  

4. **Security and simplicity**  
   No extra network surfaces, auth layers, or web components to patch.  
   Fewer moving parts at bootstrap time.

## Consequences

**Positive**  
- Minimal operational footprint — zero bundled web UIs.  
- Compatible with the most popular TUIs and GUIs.  
- Encourages scripting, AI integration, and local experimentation.  
- Aligns with Kubernetes’ composable and declarative design philosophy.  

**Negative**  
- No single “official” GUI view of the cluster.  
- Teams must manage their own visualization preferences.  

## Decision Summary

> `k8s-boot` provides a **headless, API-centric foundation**.  
> Any standard Kubernetes GUI or TUI — especially **k9s** or **Headlamp** — can be used on top for a non-CLI experience.  
> The platform itself remains pure, stable, and automation-friendly, leaving UX decisions to the user.