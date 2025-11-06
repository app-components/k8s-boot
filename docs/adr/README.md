# Architecture Decision Record Index

This document lists all Architecture Decision Records (ADRs) for the **k8s-boot** project.  
Each ADR captures a significant technical or architectural choice, its rationale, and its consequences.  
Together, they form the historical and philosophical foundation of the k8s-boot design.

## Core Decisions

| No. | Title | Summary |
|-----|--------|----------|
| [**001 – Layered Kubernetes Bootstrapping Model**](001-layered-platform.md) | Defines the 4-layer model (Infrastructure, Bootstrap, Core Platform, Applications) and establishes **k8s-boot** as the canonical Layer 1 baseline. |
| [**002 – Bootstrap Philosophy and Scope**](002-bootstrap-philosophy.md) | Clarifies what k8s-boot includes (Flux Source + Kustomize + Notification + ESO) and excludes (Helm, Image Automation, Ingress, Metrics). Goal: *a small, deterministic foundation that can manage itself.* |
| [**003 – Versioning and Upgrade Policy**](003-versioning-and-upgrade-policy.md) | Defines semantic versioning: manual minor upgrades, automatic patch adoption through moving files (e.g. `bootstrap-1.0.x.yaml`). |
| [**004 – Security and Auto-Patching Policy**](004-security-and-auto-patching.md) | Treats every patch as a mandatory security update. Clusters must always track the moving minor-line YAML to remain CVE-free. |
| [**005 – Choose FluxCD as GitOps Engine**](005-choose-fluxcd-as-gitops-engine.md) | Selects FluxCD over Carvel kapp-controller for GitOps management due to maturity, ecosystem, and the built-in Notification Controller. |
| [**006 – Disable FluxCD Helm Controller**](006-disable-flux-helm-controller.md) | Removes runtime Helm templating. All charts are rendered to static YAML at build time and reconciled via Flux Kustomize. |
| [**007 – Drift Guard Auto-Patch Mechanism**](004-drift-gaurd-auto-patch.md) | Describes how Flux’s Source + Kustomize controllers enforce Layer 1 state using embedded `GitRepository` and `Kustomization` definitions. |
| [**008 – Choose External Secrets Operator (ESO)**](005-choose-external-secrets-operator.md) | Integrates ESO as a Layer 1 component to connect Kubernetes Secrets with external vaults such as 1Password, AWS SM, or GCP SM. |
| [**009 – No Secrets in Git Repositories**](006-no-secrets-in-git-repositories.md) | Forbids encrypted or sealed secrets in source control. All secrets come from external stores through ESO; only ESO bootstrap credentials exist locally. |
| [**010 – Always Use Server-Side Apply (SSA)**](007-alway-use-server-side-apply.md) | Mandates `kubectl apply --server-side --force-conflicts --field-manager=k8s-boot` for idempotent, CRD-aware reconciliation. |
| [**011 – Core Platform as Pre-Rendered BOM**](008-core-platform-bom.md) | Defines Layer 2 (`k8s-core`) as a pre-rendered Bill of Materials composed of vendored upstream YAML and rendered Helm templates. |
