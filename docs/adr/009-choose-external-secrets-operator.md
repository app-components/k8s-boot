# ADR-009: Choose External Secrets Operator (ESO) for Secret Management

**Date:** 2025-11-06
**Status:** Accepted
**Context:** k8s-boot / Layer 1 design  

## Context

Every Kubernetes cluster eventually needs credentials and API tokens to integrate with external systems — DNS providers, Git hosts, registries, object stores, and certificate authorities.  
Typical examples include:

- Route 53 or Cloudflare API keys for `cert-manager` DNS-01 challenges  
- GitHub PAT tokens for FluxCD access  
- API keys for external services used by apps 

Many of these API keys are created on consoles or CLIs and need to be stored somewhere secrue, the consoles
typcially only show the key when it gets cretead. Tools like 1Password are great for storing these scerets.

All of these integrations depend on **Kubernetes Secrets**.  
The problem isn’t whether Secrets are secure inside Kubernetes — it’s **how they get there**, consistently and reproducibly.

Historically, secrets are managed via ad-hoc shell scripts or encrypted YAML (SOPS, Sealed Secrets), both of which mix sensitive material into Git.  
This creates operational overhead, makes automation brittle, and adds security risk.

We need a mechanism that:

- Integrates with **existing secret backends** (1Password, Vault, AWS, GCP, Azure)  
- Expresses secret mapping **declaratively in Git** but without storing secret values or ciphertext  
- Works with Flux and Kustomize under full GitOps control  
- Requires **only one bootstrap secret**, created manually once per cluster  

## Decision

Adopt **External Secrets Operator (ESO)** as the standard mechanism for secret management in all clusters bootstrapped by `k8s-boot`.  
ESO will be installed as a **core, non-optional component** of Layer 1 alongside FluxCD.

Clusters will:

1. Create a single Kubernetes Secret manually — the service-account credentials used by ESO to access the external backend.  
2. Define `SecretStore` or `ClusterSecretStore` objects pointing to that backend.  
3. Declare `ExternalSecret` resources describing which remote keys map to which Kubernetes Secrets.  
4. Let ESO continuously synchronize and refresh those Secrets.

This completely removes the need to store plaintext or encrypted secrets in Git.

## Rationale

### Why ESO

| Requirement | ESO Capability | Result |
|--------------|----------------|---------|
| **Integration with existing vaults** | Supports 1Password, Vault, AWS SM, GCP SM, Azure KV, etc. | Unified pattern for enterprise backends |
| **Declarative GitOps workflow** | `ExternalSecret` CRDs map remote keys to K8s Secrets | Reproducible without embedding values |
| **Continuous reconciliation** | ESO periodically syncs and rotates secrets | Self-healing, no rotation scripts |
| **Kubernetes-native model** | Produces standard K8s Secret objects | Works with all controllers |
| **Large community and backing** | Maintained by CNCF contributors and vendors | Ecosystem stability |
| **Zero secrets in Git** | Only metadata and mappings stored in Git | Eliminates encrypted YAML management |

### Why not SOPS or Sealed Secrets
- These tools focus on **encrypting secrets for Git**, not integrating with external vaults.  
- They require key rotation, re-encryption, and tool-specific workflows.  
- They duplicate the role already handled by enterprise-grade secret backends.  
- In this architecture, **no secret—encrypted or plaintext—belongs in Git**.

### Why not Vault Agent or CSI Driver
- Injects secrets at runtime via sidecars or volumes, bypassing the GitOps reconciliation loop.  
- Adds complex runtime dependencies and breaks the Kubernetes Secrets API contract.  
- ESO achieves the same goal declaratively and centrally.

## Consequences

### Positive
- Unified, declarative pattern for all external integrations.  
- Enables higher-level platform components (cert-manager, external-dns, etc.) to install without manual secrets.  
- Eliminates ad-hoc bootstrap scripts.  
- Scales across environments by changing only the backend configuration.  
- Simplifies security auditing — no secrets in Git history.

### Negative
- Requires network access to the external secret backend.  
- ESO must be operational before dependent controllers start.  
- Each cluster needs a bootstrap credential for ESO itself.

## Implementation Notes

- ESO manifests and CRDs are bundled in `k8s-boot bootstrap.yaml`.  
- Flux’s drift-guard includes ESO to ensure self-healing.  
- Bootstrap scripts (`bootstrap.sh`) create exactly one Secret manually containing the service-account credential for ESO.  
- All other Secrets must be declared as `ExternalSecret` resources and managed automatically.  

## Alternatives Considered

| Option | Description | Outcome |
|---------|--------------|----------|
| **SOPS + Flux** | Encrypt YAML and commit to Git | Rejected – no backend integration |
| **Sealed Secrets** | Controller decrypts per-env ciphertext | Rejected – complex key rotation |
| **Vault Agent or CSI Driver** | Inject at runtime | Rejected – breaks GitOps model |
| **ESO (chosen)** | Bridge external vaults to K8s Secrets | ✅ Accepted |

## Policy: “No Secrets in Git”

All repositories managed by `k8s-boot`, `k8s-core`, and application layers must contain **zero secret values**, encrypted or plaintext.  
Git should only hold:
- `SecretStore` and `ExternalSecret` definitions  
- The single bootstrap Secret for ESO may be created manually via `kubectl create secret` but must never be checked in.

## References

- [External Secrets Operator Docs](https://external-secrets.io/)  
- [1Password Service Account Integration](https://developer.1password.com/docs/cli/kubernetes/)  
- [FluxCD Integration Guide](https://external-secrets.io/guides/getting-started-flux/)  
- [ADR-001 Layered Platform Model](./001-layered-platform.md)
- [ADR-005 Choose FluxCD as GitOps Engine](./005-choose-fluxcd-as-gitops-engine.md)

**Decision Summary:**  
Adopt **External Secrets Operator** as a mandatory part of Layer 1 (`k8s-boot`).  
ESO enables declarative integration with external vaults and secret managers while maintaining the principle of **no secrets in Git**.  
Only one manually created Secret is permitted — the credential that grants ESO access to the chosen backend.  
All other Secrets must originate from ESO.