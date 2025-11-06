# ADR-003: Versioning and Upgrade Policy

**Date:** 2025-11-06  
**Status:** Accepted  
**Deciders:** Platform Engineering  
**Context:** k8s-boot / k8s-core projects  

## Context and Problem Statement

A reproducible platform requires more than declarative manifests; it needs a **clear, predictable upgrade model**.  
Without explicit versioning discipline, foundational components (Flux, ESO, cert-manager, etc.) drift independently, producing clusters that behave differently even when they appear “up to date.”

We must define:

* how versions are assigned to each layer,  
* what constitutes a patch, minor, or major release,  
* who performs upgrades, and  
* how automation interacts with human control.

This ADR establishes the **semantic versioning and upgrade policy** for all `k8s-boot` and `k8s-core` artifacts.

## Decision

Adopt **Semantic Versioning (semver.org)** across every layer and enforce a **manual-minor / auto-patch** upgrade policy.

| Version Type | Example | Change Scope | Upgrade Mechanism |
|---------------|----------|--------------|------------------|
| **Patch (x.y.Z)** | 1.0 → 1.0.6 | Security fixes / minor upstream updates | Re-apply tracking file (`bootstrap-1.0.x.yaml`) – automated safe upgrade |
| **Minor (x.Y.z)** | 1.0 → 1.1 | Feature additions / component bump | Manual operator action with changelog review |
| **Major (X.y.z)** | 1.x → 2.0 | Breaking changes / K8s API bumps | Manual migration with guide |

Each release line (e.g. `1.0`) is self-contained and immutable.  
New patches replace only the tracking artifact; all historical versions remain archived under `release/<minor>/`.

### Immutable Artifacts

* Every published manifest (`bootstrap-1.0.5.yaml`, `platform-1.0.5.yaml`) is **immutable** once tagged.  
* Tracking files (`*-1.0.x.yaml`) advance to the latest patch but keep the same URL for operational simplicity.  
* Changelogs are generated per minor line using `git-cliff`.

### Upgrade Philosophy

1. **Upgrades are applied, not performed.**  
   There is no in-cluster logic that mutates itself; operators apply a new manifest.

2. **Minor and major releases require intent.**  
   Humans or pipelines decide to move between lines after reviewing release notes.

3. **Patch releases are safe and repeatable.**  
   Clusters re-apply the tracking file periodically to pull security fixes without side effects.

4. **Rollbacks are explicit.**  
   Any previous artifact can be re-applied to restore state; no implicit downgrade automation.

## Rationale

| Concern | Policy Response |
|----------|----------------|
| **Stability vs Velocity** | Minor/major releases require intentional promotion; patches flow safely. |
| **Auditability** | Immutable artifacts and changelogs create a verifiable history of cluster state. |
| **Predictable Upgrades** | Version numbers map directly to manifest content; no implicit dependency updates. |
| **Air-gapped Clusters** | Each manifest contains all dependencies – no runtime fetch needed. |
| **Disaster Recovery** | Any cluster can be rebuilt from its applied bootstrap version alone. |

## Responsibilities

| Actor | Responsibility |
|-------|----------------|
| **Maintainers** | Integrate upstream Flux/ESO releases, build new patch/minor artifacts, update tracking files, generate CHANGELOG.md and tag releases. |
| **Cluster Operators** | Re-apply tracking file periodically for patches, and explicitly apply new minor/major versions after validation. |
| **Flux Controllers** | Enforce drift within a given line only – never cross version boundaries automatically. |

## Security Alignment

Patch releases are **security-critical** and must be applied automatically or on a fixed schedule to ensure clusters remain free of known vulnerabilities (CVEs).  
Operators are expected to re-apply the tracking file (`bootstrap-1.0.x.yaml`, `platform-1.0.x.yaml`) through an automated process such as a CI job or GitOps reconciliation loop.  

> Automation of patch upgrades is a **security control**, not an operational optimization.  
> Clusters that fail to apply the latest patch are considered non-compliant with baseline security policy.

For complete policy details, see [ADR-004 – Security and Auto-Patching Policy](./004-security-and-auto-patching.md).

## Implementation Notes

* All `kubectl apply` operations must use  
  `--server-side --force-conflicts --field-manager=k8s-boot`  
  for consistent ownership and idempotency.  
* CI pipelines validate that each release tag corresponds to exact manifest hashes.  
* Release URLs follow a predictable pattern:  

```bash
# Fixed version
https://raw.githubusercontent.com/app-components/k8s-boot/main/release/1.0/bootstrap-1.0.5.yaml

# Patch-tracking file
https://raw.githubusercontent.com/app-components/k8s-boot/main/release/1.0/bootstrap-1.0.x.yaml
```
## Consequences

### Positive
* Clusters remain deterministic yet easy to update within a line.  
* Security patches can be applied automatically without risk.  
* Version alignment between `k8s-boot` and `k8s-core` is transparent.  
* Supports air-gapped and offline modes naturally.  

### Negative
* Requires human discipline to promote minor/major lines.  
* Operators must regularly re-apply the tracking file for patches.  
* Slightly slower feature adoption due to manual review process.  

## Relationship to Other ADRs

| Related ADR | Relationship |
|--------------|--------------|
| **001 – Layered Model** | Defines where versioning boundaries exist across layers. |
| **002 – Bootstrap Philosophy** | Describes what is versioned inside Layer 1. |
| **004 – Security and Auto-Patching** | Expands on the automation and CVE-response aspects. |
| **008 – Core Platform BOM** | Inherits the same semver and upgrade rules for Layer 2. |

## Decision Summary

Adopt **semantic versioning and manual-minor / auto-patch upgrade policy** across all layers.  
All releases are immutable, versioned artifacts distributed as single YAML bundles.  
Operators advance clusters by re-applying the appropriate tracking file for patches and explicitly switching versions for minor or major upgrades.  
Automatic patch re-application is treated as a **mandatory security safeguard** ensuring clusters remain CVE-free and consistent.