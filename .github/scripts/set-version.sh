#!/bin/bash
#
# Sets the version in ExFigCommand.swift from a git tag or argument.
#
# Usage:
#   ./set-version.sh              # Uses GITHUB_REF environment variable
#   ./set-version.sh 1.2.3        # Uses provided version
#
set -euo pipefail

# Get version from argument or GITHUB_REF
if [[ $# -ge 1 ]]; then
    VERSION="$1"
else
    if [[ -z "${GITHUB_REF:-}" ]]; then
        echo "Error: No version provided and GITHUB_REF not set"
        echo "Usage: $0 <version>"
        exit 1
    fi
    VERSION="${GITHUB_REF#refs/tags/}"
fi

# Validate version format (semver)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format '$VERSION'. Expected semver (e.g., 1.0.0)"
    exit 1
fi

# Find repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FILE="$REPO_ROOT/Sources/ExFig/ExFigCommand.swift"

# Check file exists
if [[ ! -f "$FILE" ]]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

# Check that the pattern exists before replacing
if ! grep -q 'static let version = "' "$FILE"; then
    echo "Error: Version string not found in $FILE"
    exit 1
fi

# Replace version
sed -i '' "s/static let version = \".*\"/static let version = \"$VERSION\"/" "$FILE"

# Verify replacement succeeded
if ! grep -q "static let version = \"$VERSION\"" "$FILE"; then
    echo "Error: Version replacement failed"
    exit 1
fi

echo "Version set to: $VERSION"
