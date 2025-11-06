# Kubernetes Boot (k8s-boot)

k8s-boot is a reproducible, versioned, zero-configuration baseline for Kubernetes.

One `kubectl apply` command. 60 seconds later you have FluxCD and External Secrets Operator. Build your platform on top of it.

> **A foundation you can trust - so you can focus on what makes your platform unique.**

Inspired by Spring Boot and Ruby on Rails, k8s-boot embraces convention over configuration. By making reasonable choices about the foundation layer, it removes decisions that don't differentiate your platform. You get a stable, tested baseline and can focus on building what makes your platform unique.

---

## The Architecture

`k8s-boot` is **Layer 1** in a 4-layer model:

| Layer                        | Description                                                                          | Owner                       |
| ---------------------------- | ------------------------------------------------------------------------------------ | --------------------------- |
| **Layer 0 – Infrastructure** | Raw Kubernetes cluster                                                               | Your cloud/infra tooling    |
| **Layer 1 – k8s-boot**       | FluxCD + ESO baseline                                                                | **k8s-boot (this repo)**    |
| **Layer 2 – Platform Core**  | Ingress, cert-manager, observability, etc.                                           | Your platform repo          |
| **Layer 3 – Applications**   | Actual workloads                                                                     | Your application repos      |

k8s-boot owns Layer 1 and nothing else. Everything above it is yours to define.

---

## How It Works

```bash
kubectl apply -f https://github.com/app-components/k8s-boot/releases/download/v1.0.0/bootstrap.yaml
```

This single manifest installs FluxCD and External Secrets Operator, then creates a Flux Kustomization that continuously reconciles against the k8s-boot repo to prevent version drift.

After about 60 seconds, you have a GitOps-native cluster with FluxCD managing deployments and ESO ready to sync secrets. **That's all k8s-boot provides.**

### What's Next

k8s-boot gives you the foundation. You build the platform on top of it.

Your platform repo (Layer 2+) will typically include:
- Ingress controllers
- Certificate management (cert-manager)
- Observability and monitoring
- SecretStores for ESO (ESO is installed, but you configure the backends)
- Databases or stateful services
- Your actual applications

Create a Flux GitRepository and Kustomization pointing to your platform repo:

```yaml
kubectl apply -f - <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: platform
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/your-org/your-platform
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: platform-core
  namespace: flux-system
spec:
  interval: 10m
  sourceRef:
    kind: GitRepository
    name: platform
  path: ./clusters/production
  prune: true
EOF
```

From here, your platform repo controls everything above Layer 1. k8s-boot maintains the baseline while you build everything else on top.

---

## Design Philosophy

Kubernetes is designed for flexibility. k8s-boot is designed for **stability**.

> **You shouldn't have opinions about your foundation - you should have opinions about your platform.**

The foundation (Flux + ESO) should be:
- Tested and versioned together
- Boring and predictable  
- The same across all your clusters
- Someone else's decision

Your platform (ingress, databases, observability) should be:
- Customized to your needs
- Managed in your own Git repos
- Built on a foundation you trust

**k8s-boot is the boring part you don't want to think about.**

By keeping the foundation small, predictable, and versioned, k8s-boot ensures that every cluster starts the same way - regardless of where or how it's deployed. Once you have a stable baseline, you can focus on what makes your platform unique.

---

## Versioning and Upgrades

k8s-boot follows semantic versioning that directly tracks Flux and ESO upstream releases:

| k8s-boot Change | Upstream Trigger                | Example       | Meaning                                    |
| --------------- | ------------------------------- | ------------- | ------------------------------------------ |
| Patch           | Flux or ESO patch release       | 1.0.0 → 1.0.1 | Bug fixes, security patches                |
| Minor           | Flux or ESO minor release       | 1.0 → 1.1     | New features, backward compatible          |
| Major           | Flux or ESO major release       | 1.x → 2.0     | Breaking changes                           |

Each k8s-boot release is tested against the specific Flux and ESO versions it ships. Your clusters stay on those versions until you explicitly upgrade by applying a new k8s-boot release.

### How to Upgrade

```bash
# Upgrade to a new k8s-boot version
kubectl apply -f https://github.com/app-components/k8s-boot/releases/download/v1.1.0/bootstrap.yaml
```

The Flux Kustomization managed by k8s-boot will reconcile and update Flux and ESO to the new pinned versions.

---

## Kubernetes Version Support

k8s-boot supports whatever Kubernetes versions are supported by the Flux and ESO releases it ships.

Check the specific k8s-boot release notes for the tested Kubernetes version range for that release.

---

## Why It Works

GitOps with FluxCD eliminates drift and manual intervention. ESO removes the need to store secrets in Git. Together, they form a sustainable control plane for any Kubernetes environment.

Once the cluster can manage its own manifests and secrets, the rest of the platform - ingress, observability, databases - becomes just another declarative layer applied by Flux pointing to your own Git repositories.

That's the power of k8s-boot: **it gives you a cluster that can manage itself, so you can focus on building your platform.**