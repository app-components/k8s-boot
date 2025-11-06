# ADR-013: Define Layer 2 (Core Platform) as a Pre-Rendered Bill of Materials (BOM)

**Date:** 2025-11-06
**Status:** Accepted
**Context:** k8s-core / platform architecture  

## Context and Problem Statement

After a cluster is bootstrapped with **k8s-boot** (Layer 1), the next logical step is to install foundational platform components such as:

- Certificate management (`cert-manager`)  
- Database operators (`CloudNativePG`)  
- Networking / ingress (`Traefik`, `Gateway API`)  
- Observability stack (Prometheus, Grafana)  

These components define the **Core Platform** used by all environments and applications.

Many of these upstream projects distribute only **Helm charts**. However, ADR-006 disables the FluxCD Helm Controller and forbids runtime chart reconciliation.  
Therefore, we must define a repeatable way to consume Helm-based upstreams **as static, version-pinned manifests**, producing a Bill of Materials (BOM) that Flux can reconcile deterministically.

## Decision

We will implement the **Core Platform (Layer 2)** as a **pre-rendered, versioned BOM repository**, named `k8s-core`.  
Each release of `k8s-core`:

1. Uses **Carvel vendir** to fetch upstream Helm charts or YAML distributions.  
2. Renders any Helm charts to plain YAML at build time using `helm template`.  
3. Applies **Kustomize** overlays for configuration, namespace scoping, and labeling.  
4. Publishes the combined manifests as a **static release artifact** (e.g., `platform-1.0.x.yaml`).  
5. Is applied by Flux via `Kustomization` resources—never via Helm releases.

At runtime, FluxCD reconciles only the rendered YAMLs, ensuring reproducible and auditable platform installs.

## Rationale

| Requirement | Approach | Result |
|--------------|-----------|--------|
| Deterministic installs | Render charts at build time | Same YAML across clusters |
| Version pinning | vendir locks upstream SHAs | Controlled upgrades |
| Air-gapped support | All artifacts vendored | No runtime fetches |
| Simplicity | Kustomize composition only | No `values.yaml` or hooks |
| Drift correction | Flux Kustomizations | Immutable reconciliation |

This model mirrors **Layer 1 (k8s-boot)**: static manifests, versioned together, reconciled by Flux.  
Layer 2 simply expands the set of components under management.

## Implementation Details

### Repository Layout

```
k8s-core/
├── src/
│   ├── 1.0/
│   │   ├── cert-manager/
│   │   ├── cnpg/
│   │   ├── ingress/
│   │   ├── monitoring/
│   │   ├── kustomization.yaml
│   │   ├── VERSION
│   │   └── build.sh
├── release/
│   ├── 1.0/
│   │   ├── platform-1.0.0.yaml
│   │   ├── platform-1.0.x.yaml
│   │   └── CHANGELOG.md
└── README.md
```

### Build Process
1. `vendir sync` to fetch upstream components.  
2. Run `helm template` for each chart to render YAML.  
3. Apply Kustomize overlays for configuration.  
4. Generate a unified BOM:
   ```shell
   kustomize build . > ../../release/1.0/platform-1.0.0.yaml
   ```
5. Commit and tag the release (`v1.0.0`).

### Consumption
Users apply the published artifact:

```shell
kubectl apply -f https://github.com/app-components/k8s-core/releases/download/v1.0.0/platform.yaml
```

Flux then reconciles the core stack automatically.

## Alternatives Considered

| Option | Description | Outcome |
|--------|--------------|----------|
| **A. Use Helm Controller** | Re-enable Helm Controller for Layer 2 only. | Rejected – violates ADR-006; adds runtime templating complexity. |
| **B. Manual chart templating per cluster** | Operators run `helm template` locally. | Rejected – non-reproducible, error-prone. |
| **C. Pre-rendered BOM (chosen)** | Build-time rendering + GitOps delivery. | Accepted – deterministic and scalable. |

## Consequences

### Positive
- Fully declarative platform composition.  
- Single-file install for platform foundation.  
- Predictable upgrades via new versioned releases.  
- Simplifies compliance and audit processes.  
- Works identically in connected and air-gapped clusters.

### Negative
- Build pipeline must track upstream chart updates.  
- Larger repository size due to rendered YAML.  
- Less flexibility for dynamic per-environment Helm values.  

### Mitigations
- Automate vendir updates with CI (e.g., Renovate + git-cliff).  
- Use Kustomize overlays for environment customization.  

## Relationship to Other ADRs

- **ADR-001:** Defines the 4-layer model.
- **ADR-006:** Disables FluxCD Helm Controller.
- **ADR-011 (this):** Specifies the Layer 2 pattern for static, pre-rendered platform BOMs.

## References

- [Carvel vendir](https://carvel.dev/vendir/)  
- [Helm template command](https://helm.sh/docs/helm/helm_template/)  
- [FluxCD Kustomize Controller](https://fluxcd.io/flux/components/kustomize/)  
- [Kustomize best practices](https://kubectl.docs.kubernetes.io/references/kustomize/)  

**Decision Summary:**  
Define **Layer 2 (Core Platform)** as a **pre-rendered Bill of Materials** built from vendored upstream components and rendered Helm charts.  
Deliver the result as immutable, versioned YAML artifacts reconciled by FluxCD, ensuring deterministic and air-gap-friendly GitOps platform deployments.

