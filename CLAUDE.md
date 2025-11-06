# k8s-boot Repository Layout and Release Process

This document describes the structure and release workflow for the k8s-boot project.

## Repository Structure

```
k8s-boot/
├── src/
│   ├── 1.0/
│   │   ├── flux/           # Flux component manifests
│   │   ├── eso/            # External Secrets Operator manifests
│   │   ├── kustomization.yaml
│   │   ├── VERSION         # Current version (e.g., 1.0.5)
│   │   └── build.sh        # Build script for this version line
│   ├── 1.1/
│   │   ├── flux/
│   │   ├── eso/
│   │   ├── kustomization.yaml
│   │   ├── VERSION         # Current version (e.g., 1.1.2)
│   │   └── build.sh
│   └── 1.2/                # Current development version
│       ├── flux/
│       ├── eso/
│       ├── kustomization.yaml
│       ├── VERSION         # e.g., 1.2.0-dev
│       └── build.sh
├── release/
│   ├── 1.0/
│   │   ├── CHANGELOG.md
│   │   ├── bootstrap-1.0.0.yaml
│   │   ├── bootstrap-1.0.5.yaml
│   │   └── bootstrap-1.0.x.yaml    # Tracks latest 1.0.z patch
│   ├── 1.1/
│   │   ├── CHANGELOG.md
│   │   ├── bootstrap-1.1.0.yaml
│   │   ├── bootstrap-1.1.2.yaml
│   │   └── bootstrap-1.1.x.yaml    # Tracks latest 1.1.z patch
│   └── 1.2/
│       ├── CHANGELOG.md
│       └── ...
└── README.md
```

## Version Structure

k8s-boot maintains multiple active version lines in the `src/` directory:
- **Previous minor version** (e.g., `src/1.0/`) - Maintenance mode, patch releases only
- **Current stable version** (e.g., `src/1.1/`) - Active development for patches
- **Next version** (e.g., `src/1.2/`) - Development for next minor/major release

Each version directory is self-contained with its own:
- Component manifests (Flux, ESO)
- Kustomization file
- VERSION file
- build.sh script

## Semantic Versioning

k8s-boot versions directly track upstream Flux and ESO releases:

| k8s-boot Change | Upstream Trigger        | Example       |
| --------------- | ----------------------- | ------------- |
| Patch (x.y.Z)   | Flux or ESO patch       | 1.0.0 → 1.0.1 |
| Minor (x.Y.z)   | Flux or ESO minor       | 1.0 → 1.1     |
| Major (X.y.z)   | Flux or ESO major       | 1.x → 2.0     |

## Release Files

The `release/` directory mirrors the `src/` structure, with each version line in its own subdirectory:

1. **Version-specific directories** (e.g., `release/1.0/`, `release/1.1/`):
   - `CHANGELOG.md` - Generated from git commits affecting that version line
   - `bootstrap-x.y.z.yaml` - Immutable versioned files (created once, never modified)
   - `bootstrap-x.y.x.yaml` - Mutable tracking file pointing to latest patch in that line

This structure allows users to find all artifacts for a specific version line in one place.

## Release Workflow

### Patch Release (x.y.Z)

Example: Releasing 1.0.6 when Flux 2.5.9 is released

```bash
# 1. Navigate to the version directory
cd src/1.0

# 2. Update Flux/ESO manifests with new patch versions
# ... edit flux/ or eso/ manifests ...

# 3. Update VERSION file
echo "1.0.6" > VERSION

# 4. Run build script
./build.sh
# This generates:
# - release/1.0/bootstrap-1.0.6.yaml (new immutable file)
# - Updates release/1.0/bootstrap-1.0.x.yaml (overwrites)
# - Updates release/1.0/CHANGELOG.md

# 5. Commit with conventional commit
git add .
git commit -m "fix(1.0): Update Flux to 2.5.9"

# 6. Tag the release
git tag v1.0.6

# 7. Push
git push origin main --tags
```

### Minor Release (x.Y.z)

Example: Releasing 1.2.0 when Flux 2.7.0 is released

```bash
# 1. Copy previous version as starting point (if needed)
cd src
cp -r 1.1 1.2
cd 1.2

# 2. Update Flux/ESO manifests with new minor versions
# ... edit flux/ or eso/ manifests ...

# 3. Update VERSION file
echo "1.2.0" > VERSION

# 4. Run build script
./build.sh
# This generates:
# - release/1.2/bootstrap-1.2.0.yaml (new immutable file)
# - Creates release/1.2/bootstrap-1.2.x.yaml (new tracking file)
# - Updates release/1.2/CHANGELOG.md

# 5. Commit with conventional commit
git add .
git commit -m "feat: Upgrade to Flux 2.7.0"

# 6. Tag the release
git tag v1.2.0

# 7. Push
git push origin main --tags
```

### Major Release (X.y.z)

Same as minor release, but uses `BREAKING CHANGE:` in commit message:

```bash
git commit -m "feat!: Upgrade to Flux 3.0.0

BREAKING CHANGE: Flux 3.0 requires Kubernetes 1.28+"
```

## build.sh Script Behavior

The `build.sh` script in each version directory (e.g., `src/1.0/build.sh`):

1. Reads the VERSION file (e.g., `1.0.6`)
2. Runs `kustomize build . > ../../release/1.0/bootstrap-${VERSION}.yaml`
3. Updates the tracking file: `cp ../../release/1.0/bootstrap-${VERSION}.yaml ../../release/1.0/bootstrap-1.0.x.yaml`
4. Generates the changelog scoped to this version line:
   ```bash
   git cliff --include-path "src/1.0/**/*" > ../../release/1.0/CHANGELOG.md
   ```

The script uses git-cliff's monorepo support to filter commits to only those affecting the specific version directory.

## User-Facing URLs

Users reference bootstrap files via raw GitHub URLs:

```bash
# Pin to exact version (never auto-updates)
kubectl apply -f https://raw.githubusercontent.com/app-components/k8s-boot/main/release/1.0/bootstrap-1.0.5.yaml

# Auto-update to patch releases in 1.0.x line
kubectl apply -f https://raw.githubusercontent.com/app-components/k8s-boot/main/release/1.0/bootstrap-1.0.x.yaml

# View changelog for a version line
curl https://raw.githubusercontent.com/app-components/k8s-boot/main/release/1.0/CHANGELOG.md
```

Or via git tags for immutable references:

```bash
kubectl apply -f https://raw.githubusercontent.com/app-components/k8s-boot/v1.0.5/release/1.0/bootstrap-1.0.5.yaml
```

## Air-Gapped Environments

Users can clone the repository and host it internally:

```bash
git clone https://github.com/app-components/k8s-boot
# Mirror to internal git server
# Reference via internal URLs
kubectl apply -f https://internal-git/k8s-boot/release/1.0/bootstrap-1.0.5.yaml
```

## Maintenance Policy

- **Current stable**: Active development, receives all patches
- **Previous minor**: Maintenance mode, receives critical security patches only
- **Older versions**: End of life, no updates

When a new minor version is released, consider deprecating versions older than N-2.

## Conventional Commits

Use conventional commits for all changes:
- `fix:` - Patch release (component patch updates)
- `feat:` - Minor release (component minor updates)
- `feat!:` or `BREAKING CHANGE:` - Major release (component major updates)

The changelog is automatically generated from these commits using `git-cliff`.

## Notes

- All releases are on a single `main` branch
- No GitHub Releases are used - everything is in the repository
- Each version line in `src/` is independent and can be updated separately
- The `release/` directory mirrors `src/` structure with each version line in its own subdirectory
- Each version line has its own CHANGELOG.md generated using git-cliff with path filtering
- Git tags (`vx.y.z`) mark specific releases for immutable references