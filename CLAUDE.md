# k8s-boot Repository Layout and Release Process

This document describes the structure and release workflow for the k8s-boot project.

## Repository Structure

```
k8s-boot/
├── src/
│   ├── 1.0/              # Self-contained version line
│   │   ├── flux/         # Flux manifests (synced via vendir)
│   │   ├── eso/          # ESO manifests (synced via vendir, templated from Helm)
│   │   ├── kustomization.yaml
│   │   ├── vendir.yml    # Dependency versions
│   │   ├── VERSION
│   │   └── build.sh
│   ├── 1.1/
│   └── 1.2/
├── release/
│   ├── 1.0/
│   │   ├── bootstrap-1.0.x.yaml    # Tracking file (recommended)
│   │   ├── bootstrap-1.0.5.yaml    # Immutable versions
│   │   └── CHANGELOG.md
│   └── 1.1/
└── docs/adr/             # Architecture Decision Records
```

## Core Principles (See ADRs for Details)

**Layer 1 Bootstrap** (ADR-001, ADR-002):
- Only FluxCD (Source + Kustomize + Notification) + ESO
- Helm Controller explicitly disabled (ADR-006)
- Static manifests applied via kubectl, not Flux controllers
- Flux monitors for drift but doesn't install Layer 1

**Namespaces** (ADR-011):
- Use upstream defaults: `flux-system`, `external-secrets`
- No custom prefixes or rebranding
- Clusters are cattle, not pets

**Security** (ADR-004):
- All patches are mandatory security updates
- Use tracking files (`bootstrap-1.0.x.yaml`) for auto-patching
- Pinned versions discouraged in production

## Dependency Management (vendir)

k8s-boot uses Carvel vendir for reproducible dependency management:

**Workflow:**
1. Edit `vendir.yml` to update component versions
2. Run `vendir sync` to download dependencies
3. Template ESO Helm chart: `helm template external-secrets ... --namespace external-secrets > eso/install.yaml`
4. Run `build.sh` to generate release manifests

## Semantic Versioning

| k8s-boot Change | Upstream Trigger | Example |
|-----------------|------------------|---------|
| Patch (x.y.Z) | Flux or ESO patch | 1.0.0 → 1.0.1 |
| Minor (x.Y.z) | Flux or ESO minor | 1.0 → 1.1 |
| Major (X.y.z) | Flux or ESO major | 1.x → 2.0 |

## kubectl Apply Standard (ADR-010)

**All `kubectl apply` operations MUST use:**
```bash
kubectl apply --server-side --force-conflicts --field-manager=k8s-boot -f <manifest>
```

## Release Workflow

### Patch Release (x.y.Z)

```bash
cd src/1.0
# 1. Update vendir.yml with new patch versions
# 2. vendir sync
# 3. Template ESO if needed: helm template external-secrets ... --namespace external-secrets > eso/install.yaml
# 4. Update VERSION file: echo "1.0.6" > VERSION
# 5. ./build.sh  # Generates release/1.0/bootstrap-1.0.6.yaml and updates tracking file
# 6. Test: kind create cluster && kubectl apply --server-side -f ../../release/1.0/bootstrap-1.0.6.yaml
# 7. Commit: git commit -m "fix(1.0): Update Flux to 2.5.9"
# 8. Tag: git tag v1.0.6
# 9. Push: git push origin main --tags
```

### Minor Release (x.Y.z)

```bash
cd src && cp -r 1.1 1.2 && cd 1.2
# 1. Update vendir.yml with new minor versions
# 2. vendir sync
# 3. Template ESO: helm template external-secrets ... --namespace external-secrets > eso/install.yaml
# 4. Update VERSION: echo "1.2.0" > VERSION
# 5. ./build.sh  # Creates new release/1.2/ directory with tracking file
# 6. Commit: git commit -m "feat: Upgrade to Flux 2.7.0"
# 7. Tag: git tag v1.2.0
# 8. Push: git push origin main --tags
```

### Major Release (X.y.z)

Same as minor, use `feat!:` or `BREAKING CHANGE:` in commit message.

## build.sh Behavior

1. Reads VERSION file
2. Runs `kustomize build . > ../../release/1.0/bootstrap-${VERSION}.yaml`
3. Updates tracking file: `cp ... ../../release/1.0/bootstrap-1.0.x.yaml`
4. Generates CHANGELOG: `git cliff --include-path "src/1.0/**/*" > ../../release/1.0/CHANGELOG.md`

## User-Facing URLs

**Recommended (automatic security updates):**
```bash
kubectl apply --server-side --force-conflicts --field-manager=k8s-boot \
  -f https://raw.githubusercontent.com/app-components/k8s-boot/main/release/1.0/bootstrap-1.0.x.yaml
```

**Pinned version (audit/rollback only, NOT recommended for production):**
```bash
kubectl apply --server-side --force-conflicts --field-manager=k8s-boot \
  -f https://raw.githubusercontent.com/app-components/k8s-boot/main/release/1.0/bootstrap-1.0.5.yaml
```

## Conventional Commits

- `fix:` - Patch release
- `feat:` - Minor release
- `feat!:` or `BREAKING CHANGE:` - Major release

## Key Implementation Notes

- Flux Helm Controller is disabled (ADR-006) - ESO templated from Helm at build time
- All components use upstream default namespaces: `flux-system`, `external-secrets` (ADR-011)
- Tracking files (`bootstrap-1.0.x.yaml`) are the recommended consumption method (ADR-004)
- Drift guard uses branch-based tracking, not tags - enables auto-patching within minor line (ADR-007)
- `vendir.lock.yml` files must be committed for reproducible builds
- All releases on single `main` branch with git tags (`vx.y.z`) for immutable references