#!/bin/bash
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Read version from VERSION file
VERSION=$(cat VERSION | tr -d '[:space:]')

if [ -z "$VERSION" ]; then
    echo "Error: VERSION file is empty"
    exit 1
fi

echo "Building k8s-boot version $VERSION"

# Parse version into major.minor.patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Determine release directory
RELEASE_DIR="../../release/${MAJOR}.${MINOR}"
mkdir -p "$RELEASE_DIR"

# Build the bootstrap manifest
echo "Running kustomize build..."
kustomize build . > "${RELEASE_DIR}/bootstrap-${VERSION}.yaml"

# Update tracking file (x.y.x)
echo "Updating tracking file: bootstrap-${MAJOR}.${MINOR}.x.yaml"
cp "${RELEASE_DIR}/bootstrap-${VERSION}.yaml" "${RELEASE_DIR}/bootstrap-${MAJOR}.${MINOR}.x.yaml"

# Generate changelog using git-cliff (if available)
if command -v git-cliff &> /dev/null; then
    echo "Generating changelog..."
    git cliff --include-path "src/${MAJOR}.${MINOR}/**/*" > "${RELEASE_DIR}/CHANGELOG.md" 2>/dev/null || echo "# Changelog\n\nNo commits yet." > "${RELEASE_DIR}/CHANGELOG.md"
else
    echo "git-cliff not found, skipping changelog generation"
fi

echo "Build complete!"
echo "Generated files:"
echo "  - ${RELEASE_DIR}/bootstrap-${VERSION}.yaml"
echo "  - ${RELEASE_DIR}/bootstrap-${MAJOR}.${MINOR}.x.yaml"
if [ -f "${RELEASE_DIR}/CHANGELOG.md" ]; then
    echo "  - ${RELEASE_DIR}/CHANGELOG.md"
fi
