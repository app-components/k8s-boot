# ADR-001: Establish Layered Kubernetes Bootstrapping Model (k8s-boot)

**Date:** 2025-11-06  
**Status:** Accepted  
**Deciders:** Platform Engineering  
**Context:** k8s-boot / platform architecture  

## Context and Problem Statement

Modern Kubernetes clusters are often bootstrapped in ad-hoc ways, with teams manually installing foundational components (e.g., FluxCD, External Secrets, cert-manager) using scripts or Helm.  
This results in:
- Divergent bootstrap sequences per environment  
- Undocumented dependencies and ordering  
- Difficulty reproducing clusters consistently  
- Opaque version drift between foundational components  

The **k8s-boot** project exists to standardize this first stage of cluster bring-up.

We need a simple, declarative, and reproducible baseline that installs the minimum viable control plane for GitOps-driven operations—without imposing opinions on higher-level platform components or applications.

## Decision

Adopt a **four-layer model** for platform composition and define **k8s-boot** as the canonical implementation of **Layer 1 – Bootstrap**.

### The Four Layers

| Layer | Description | Responsibility | Examples |
|-------|--------------|----------------|-----------|
| **Layer 0 – Infrastructure** | Provisioning of the raw cluster (nodes, networking, storage). | Infra / SRE teams | Terraform, Cluster API, managed K8s (EKS, GKE, AKS). |
| **Layer 1 – Bootstrap** | Declarative baseline that installs FluxCD and External Secrets Operator (ESO) for GitOps + secret management. | **k8s-boot** | FluxCD, ESO. |
| **Layer 2 – Core Platform** | Shared platform services managed via GitOps. | Platform engineering teams | cert-manager, CloudNativePG, ingress, observability stack. |
| **Layer 3 – Applications** | Business workloads and environments. | Developer / product teams | Microservices, APIs, front-ends. |

Each layer builds on the previous one but remains logically independent and versioned separately.

## Rationale

### Design Goals

1. **Deterministic Bootstrapping**  
   A single manifest (`bootstrap.yaml`) installs all required Layer 1 components.  
   Example:  
   ```bash
   kubectl apply -f https://github.com/app-components/k8s-boot/releases/download/v1.0.0/bootstrap.yaml
   ```

2. **Self-Healing via GitOps**  
   FluxCD continuously reconciles the baseline repository to detect and correct drift in foundational components.

3. **Immutable, Versioned Artifacts**  
   Each release of `k8s-boot` pins FluxCD and ESO versions tested together and stored under `release/<version>/`.

4. **Composable Architecture**  
   Higher layers (e.g., `k8s-core`) consume `k8s-boot` as a dependency but can be replaced or upgraded independently.

5. **Convention over Configuration**  
   Reasonable defaults remove non-differentiating choices while remaining extensible via Kustomize overlays.

## Consequences

### Positive
- Consistent, repeatable cluster bootstraps across environments.  
- Clear separation of concerns between bootstrap, platform, and application layers.  
- Simplified upgrade path using new bootstrap manifests.  
- Enables air-gapped and auditable GitOps workflows.  
- Easier onboarding—developers start from a working GitOps baseline.

### Negative
- Requires maintaining versioned manifests for each layer.  
- Upstream FluxCD/ESO changes must be integrated and tested before release.  
- Slightly slower feature adoption since Layer 1 is pinned to stable versions.

## Implementation Notes

- `k8s-boot` releases are pure static YAML, built via `vendir` + `kustomize`.  
- FluxCD’s Helm Controller is explicitly excluded (see [ADR 0002](./0002-disable-flux-helm-controller.md)).  
- Upgrades occur by applying a new bootstrap manifest (e.g., `bootstrap-1.1.x.yaml`).  
- FluxCD monitors Layer 1 for drift but does not reinstall it.  
- Downstream projects (`k8s-core`, platform repos) define their own Kustomizations targeting Layer 2 +.  

## Example Lifecycle

```shell
# 1. Bootstrap the cluster
kubectl apply -f https://github.com/app-components/k8s-boot/releases/download/v1.0.0/bootstrap.yaml

# 2. FluxCD comes online and starts reconciling Layer 1
# 3. Apply the next layer (core platform)
kubectl apply -f https://github.com/app-components/k8s-core/releases/download/v1.0.0/platform.yaml

# 4. Developers deploy applications via GitOps
git push origin main
```

## Alternatives Considered

| Option | Description | Outcome |
|--------|--------------|----------|
| **Ad-hoc bootstrap scripts** | Imperative bash or Helm installs for Flux/ESO. | Rejected – non-deterministic and unversioned. |
| **Single monolithic platform repo** | Combine bootstrap, platform, and apps. | Rejected – breaks separation of concerns. |
| **Dynamic Helm-based bootstrap** | Use Helm Controller to install Layer 1 components. | Rejected – runtime templating and ordering issues. |

## References

- [FluxCD Documentation](https://fluxcd.io/docs/)
- [External Secrets Operator](https://external-secrets.io/)
- [Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [Carvel vendir](https://carvel.dev/vendir/)
- [GitOps Principles](https://opengitops.dev/#principles)


**Decision Summary:**  
Adopt a **layered Kubernetes architecture** and implement **k8s-boot** as the immutable, GitOps-managed Layer 1 foundation that installs FluxCD and ESO.  
This baseline provides a reproducible, self-healing, and versioned starting point for all higher-level platform and application layers.

