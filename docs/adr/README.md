# Architecture Decision Record Index

This document lists all Architecture Decision Records (ADRs) for the **k8s-boot** project.

Each ADR captures a significant technical or architectural choice, its rationale, and its consequences. Together, they form the historical and philosophical foundation of the k8s-boot design.

## How to Read These ADRs

The ADRs are organized to tell a story: **vision → philosophy → policy → technology choices → implementation details**.

We start by establishing **what we're building and why** (the vision and philosophy), then define **governance policies** (versioning, security), and finally make **technology choices** that align with those principles. This structure ensures every technical decision can be traced back to a foundational principle.

## Foundation: Vision and Philosophy

These ADRs establish the architectural vision and core philosophy that guides all subsequent decisions.

| No. | Title | Summary |
|-----|--------|----------|
| [**001 – Layered Kubernetes Bootstrapping Model**](001-layered-platform.md) | Defines the 4-layer model (Infrastructure, Bootstrap, Core Platform, Applications) and establishes **k8s-boot** as the canonical Layer 1 baseline. |
| [**002 – Bootstrap Philosophy and Scope**](002-bootstrap-philosophy-and-scope.md) | Clarifies what k8s-boot includes (Flux Source + Kustomize + Notification + ESO) and excludes (Helm, Image Automation, Ingress, Metrics). Goal: *a small, deterministic foundation that can manage itself.* |
| [**003 – User Interface and Interaction Philosophy**](003-user-interface-and-interaction-philosophy.md) | k8s-boot is UI-agnostic and headless. No built-in dashboards or web UIs. Users choose their preferred tools (k9s, Headlamp, kubectl, etc.) for a composable, automation-friendly experience. |

## Governance: Lifecycle and Security Policies

These ADRs define how we manage change, upgrades, and security across the platform lifecycle.

| No. | Title | Summary |
|-----|--------|----------|
| [**004 – Versioning and Upgrade Policy**](004-versioning-and-upgrade-policy.md) | Defines semantic versioning: manual minor upgrades, automatic patch adoption through moving files (e.g. `bootstrap-1.0.x.yaml`). |
| [**005 – Security and Auto-Patching Policy**](005-security-and-auto-patching-policy.md) | Treats every patch as a mandatory security update. Clusters must always track the moving minor-line YAML to remain CVE-free. |

## Technology Choices: Components and Configuration

These ADRs select specific technologies and define how they should be configured to align with our philosophy.

| No. | Title | Summary |
|-----|--------|----------|
| [**006 – Choose FluxCD as GitOps Engine**](006-choose-fluxcd-as-gitops-engine.md) | Selects FluxCD over Carvel kapp-controller for GitOps management due to maturity, ecosystem, and the built-in Notification Controller. |
| [**007 – Disable FluxCD Helm Controller**](007-disable-flux-helm-controller.md) | Removes runtime Helm templating. All charts are rendered to static YAML at build time and reconciled via Flux Kustomize. |
| [**008 – Drift Guard Strategy for Layer 1**](008-drift-guard-strategy-for-layer-1.md) | Describes how Flux's Source + Kustomize controllers enforce Layer 1 state using embedded `GitRepository` and `Kustomization` definitions. |
| [**009 – Choose External Secrets Operator (ESO)**](009-choose-external-secrets-operator.md) | Integrates ESO as a Layer 1 component to connect Kubernetes Secrets with external vaults such as 1Password, AWS SM, or GCP SM. |

## Implementation: Technical Standards and Patterns

These ADRs establish concrete implementation standards that ensure consistency and security.

| No. | Title | Summary |
|-----|--------|----------|
| [**010 – Prohibit Secrets in Git Repositories**](010-prohibit-secrets-in-git-repositories.md) | Forbids encrypted or sealed secrets in source control. All secrets come from external stores through ESO; only ESO bootstrap credentials exist locally. |
| [**011 – Always Use Server-Side Apply (SSA)**](011-always-use-server-side-apply.md) | Mandates `kubectl apply --server-side --force-conflicts --field-manager=k8s-boot` for idempotent, CRD-aware reconciliation. |
| [**012 – Namespace and Naming Conventions**](012-namespace-and-naming-conventions.md) | Adopts upstream default namespaces (e.g., `flux-system`, `external-secrets`) without customization. Clusters are cattle, not pets — single baseline per cluster. |

## Extension: Beyond Layer 1

This ADR extends the same principles and patterns to Layer 2 (Core Platform).

| No. | Title | Summary |
|-----|--------|----------|
| [**013 – Core Platform as Pre-Rendered BOM**](013-core-platform-bom.md) | Defines Layer 2 (`k8s-core`) as a pre-rendered Bill of Materials composed of vendored upstream YAML and rendered Helm templates. |
