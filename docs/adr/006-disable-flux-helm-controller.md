# ADR-006: Disable FluxCD Helm Controller

**Date:** 2025-11-06
**Status:** Accepted
**Context:** k8s-boot / k8s-core projects  

---

## Context and Problem Statement

FluxCD includes an optional **Helm Controller** that continuously reconciles `HelmRelease` resources against upstream Helm charts.  
While convenient for dynamic chart management, this introduces runtime templating, mutable state, and dependency-ordering issues that conflict with the design goals of **k8s-boot** and the broader **GitOps-first platform architecture**.

The platform’s goals are:

- Fully **deterministic, declarative** environments (no runtime chart rendering).  
- **Static, version-pinned manifests** built once and applied consistently across clusters.  
- A **small, stable Layer 1 footprint** suitable for bootstrapping and drift correction.  
- Support for **air-gapped and audited environments** with no runtime network fetches.

---

## Decision

We will **not deploy or depend on the FluxCD Helm Controller** in any k8s-boot or k8s-core release.  

Instead:

1. All Helm charts will be **rendered to static YAML** at build time using  
   `helm template` or Carvel `vendir` pipelines.
2. The rendered manifests will be committed to source control and  
   distributed as version-pinned artifacts (e.g., `release/1.0/platform-1.0.x.yaml`).
3. FluxCD will reconcile only **Kustomizations and Sources**, never `HelmRelease` objects.
4. Developers and platform operators will use **Kustomize overlays** for environment-specific configuration.

This ensures every object applied to a cluster is visible in Git, auditable, and identical across environments.

---

## Considered Options

| Option | Description | Outcome |
|--------|--------------|----------|
| **A. Keep Helm Controller** | Use `HelmRelease` CRDs for dynamic chart installs. | Rejected – introduces non-determinism, requires CRD dependency management, complicates air-gapped workflows. |
| **B. Disable Helm Controller (chosen)** | Render charts at build time; commit YAML; reconcile via Flux Kustomizations. | Accepted – yields reproducible, auditable GitOps pipelines. |
| **C. Hybrid** | Keep Helm Controller only for Layer 2 (k8s-core). | Rejected – increases bootstrap complexity and duplicates build logic. |

---

## Rationale

| Concern | Helm Controller Approach | Static-YAML Approach |
|----------|--------------------------|----------------------|
| **Reproducibility** | Depends on remote chart versioning | Fully pinned YAML |
| **Security / Auditability** | Release state stored in cluster secrets | All manifests visible in Git |
| **Bootstrapping** | CRDs must exist before HelmReleases apply | Single static apply works |
| **Air-gapped Support** | Requires network access to chart repos | Vendir copies charts into repo |
| **Drift Correction** | Indirect via Helm reconciliation | Direct via Flux Kustomize |
| **Operational Simplicity** | Adds controller and CRDs | Removes moving parts |

The static approach aligns with the philosophy of `k8s-boot`: **“install once, reconcile forever.”**

---

## Consequences

### Positive
- Smaller Layer 1 footprint (no Helm Controller or CRDs).
- Full Git visibility of every applied resource.
- Simplified security posture and compliance audits.
- Fewer bootstrap race conditions.
- Predictable upgrades via new manifest versions.

### Negative
- Requires CI automation to re-render Helm charts when upstream releases change.
- Less flexibility for multi-tenant teams wanting to dynamically override Helm values.
- Additional repository storage for rendered YAML.

### Mitigations
- Automate vendir + helm-template pipelines in `build.sh`.
- Encourage environment overlays through Kustomize instead of Helm values.

---

## Implementation Notes

- Remove the Helm Controller manifests from the FluxCD bundle in `k8s-boot`.
- Document this policy in `ARCHITECTURE.md` and project READMEs.
- Provide CI templates for vendir + helm-template rendering in `k8s-core`.
- Enforce linting rules that reject `HelmRelease` CRDs in downstream repos.

---

## References

- [FluxCD Helm Controller documentation](https://fluxcd.io/flux/components/helm/)
- [Carvel vendir](https://carvel.dev/vendir/)
- [Kustomize Best Practices](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [MADR template](https://adr.github.io/madr/)

---

**Decision Summary:**  
Disable FluxCD Helm Controller across all layers.  
All charts are rendered to YAML at build time and reconciled by Flux Kustomize for deterministic, auditable, and air-gap-friendly GitOps operations.