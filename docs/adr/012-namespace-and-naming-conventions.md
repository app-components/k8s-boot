# ADR-012: Namespace and Naming Conventions

**Date:** 2025-11-06
**Status:** Accepted
**Context:** k8s-boot / k8s-core

## Context

Kubernetes gives complete freedom to define namespaces and component names, but excessive customization leads to divergence from upstream defaults, fragile automation, and harder onboarding.  

`k8s-boot` aims for a **vanilla, upstream-aligned installation** that mirrors each project’s official quick-start instructions.  
Clusters are treated as **cattle, not pets** — reproducible, replaceable, and version-pinned.  

We explicitly assume:
- All clusters run **a single version** of the bootstrap and core platform components.  
- Multi-tenancy may exist at the **workload level**, but not at the **foundation level**.  
  Every tenant uses the same Flux, ESO, and networking controllers.  

## Decision

Use **standard upstream namespaces** for all system components.  
Do **not** rename, prefix, or rebrand namespaces (e.g., avoid `acme-flux-system`).  
Create only the namespaces required for the components present at each layer.

| Component | Namespace | Source |
|------------|------------|--------|
| **FluxCD** | `flux-system` | Flux default |
| **External Secrets Operator (ESO)** | `external-secrets` | ESO default |
| **Cert-Manager** | `cert-manager` | Upstream |
| **CloudNativePG** | `cnpg-system` | Upstream |
| **Envoy Gateway** | `gateway-system` | Upstream |

## Rationale

1. **Consistency with upstream documentation**  
   - Makes troubleshooting and onboarding easier.  
   - Upstream Helm/Kustomize examples work without modification.  

2. **Simplicity and predictability**  
   - Avoids custom mappings or environment-specific renames.  
   - Keeps bootstrap YAML minimal and self-descriptive.  

3. **Cattle, not pets**  
   - Clusters are ephemeral. Namespace isolation for multiple versions or forks of system components is unnecessary.  

4. **Uniform foundations for all tenants**  
   - Multi-tenant workloads share the same control-plane components.  
   - Flux, ESO, and Gateway resources are global, not per-tenant.  

## Consequences

**Positive**
- Uniform cluster layouts across environments.  
- Reduced operational complexity and documentation overhead.  
- Compatible with community and upstream tooling.  

**Negative**
- No support for parallel installations of different component versions in a single cluster (intentional).  
- Any upstream namespace rename requires a k8s-boot patch release.  

## Decision Summary

> `k8s-boot` and its dependent layers adopt **upstream namespaces exactly as published**.  
> Clusters are **cattle, not pets** — a single baseline per cluster.  
> Even in multi-tenant environments, all tenants share the same foundational control-plane components and namespaces.