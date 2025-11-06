# ADR-004: Security and Auto-Patching Policy

**Date:** 2025-11-06  
**Status:** Accepted  
**Deciders:** Platform Engineering  
**Context:** k8s-boot / k8s-core lifecycle governance  

## Context and Problem Statement

Kubernetes clusters depend on a secure baseline of controllers such as **FluxCD**, **External Secrets Operator (ESO)**, and other core services.  
These upstream projects release frequent **patches** to fix CVEs, dependency vulnerabilities, and operational bugs.  
Manual patching leads to inconsistent security posture and long exposure windows.

To keep every cluster consistent and CVE-free, `k8s-boot` must guarantee that all environments automatically adopt the latest patch within their current minor line — without any manual coordination or re-templating.

## Decision

Adopt a **continuous auto-patching policy** in which **every patch release (x.y.Z)** is treated as a **mandatory security update**.  
Clusters must always consume the **moving minor-line file** (for example `bootstrap-1.0.x.yaml`) rather than pinning to a specific patch.

### Key Mechanics

1. **Tracking Files as Security Channels**  
   - Each minor line publishes a tracking artifact (`bootstrap-1.0.x.yaml`, `platform-1.0.x.yaml`).  
   - The file always points to the latest tested and secure patch.  
   - Clusters applying this artifact automatically receive updates when new patches are released.  
   - **Pinned versions are strongly discouraged** — they will miss security fixes.

2. **Manual Promotion for Minor and Major Only**  
   - Security patches flow automatically through the moving file.  
   - Moving from 1.0 → 1.1 or higher requires intentional action after reviewing release notes.

3. **Self-Contained Artifacts**  
   - Every patch bundle includes all CRDs and manifests so that clusters can update safely even in air-gapped or offline conditions.

4. **CVE Response Workflow**  
   - Maintainers monitor upstream security advisories.  
   - When a vulnerability affects Flux, ESO, or any core component:  
     - A new patch (e.g. `1.0.7`) is published and the tracking file is updated.  
     - Clusters consuming that tracking file automatically receive the fix on next reconciliation.

## Rationale

| Goal | Policy Mechanism |
|------|------------------|
| Timely CVE remediation | Clusters always follow the latest patch in their minor line. |
| Zero manual steps for security updates | Operators apply a single tracking URL once per cluster. |
| Consistency | All clusters apply identical tested YAML bundles. |
| Auditability | Release artifacts and changelogs record exact CVE fixes. |
| Air-gapped parity | Self-contained YAML enables local mirrors without internet access. |

## Responsibilities

| Actor | Responsibility |
|-------|----------------|
| **Maintainers** | Publish patch releases with documented CVE references and update tracking files. |
| **Cluster Operators** | Apply the tracking file when bootstrapping and ensure clusters continue to follow that moving minor URL. |
| **Security Teams** | Confirm that clusters use the latest patch within each supported minor line. |

## Consequences

### Positive
- Clusters remain continuously patched and CVE-free.  
- No manual intervention for routine security maintenance.  
- Predictable and uniform state across clusters and environments.  
- Satisfies compliance expectations for timely vulnerability remediation.

### Negative
- Operators must avoid pinning to immutable patch files; doing so will freeze security updates.  
- Air-gapped clusters must mirror updated tracking artifacts regularly to stay current.  

## Relationship to Other ADRs

| ADR | Relationship |
|------|---------------|
| **003 – Versioning and Upgrade Policy** | Defines the semantic versioning framework this policy builds on. |
| **004 – Drift Guard Auto-Patch** | Provides the Flux mechanism that applies and enforces patch updates. |
| **006 – No Secrets in Git** | Ensures that patch artifacts and automation never include sensitive data. |

## 7 – Decision Summary

All patch releases are **mandatory security updates**.  
Clusters must always reference the moving minor-line artifact (e.g. `bootstrap-1.0.x.yaml`) to receive CVE and bug fixes automatically.  
Pinned patch files are explicitly unsupported because they freeze security state.  
This policy keeps every environment secure, consistent, and aligned with the latest tested baseline without requiring extra tooling or external automation.  
