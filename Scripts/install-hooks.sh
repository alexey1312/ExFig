#!/bin/bash
#
# Install and configure hk git hooks
# This script is the single source of truth for hook installation
# Called from: environment.sh, mise run setup
#

set -e

# Get project root (parent of Scripts directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo 'Setting up git hooks with hk...'

# Remove old pre-commit framework hooks if present
if [ -f ".git/hooks/pre-commit" ] && grep -q "pre-commit" ".git/hooks/pre-commit" 2>/dev/null; then
    echo 'Removing old pre-commit framework hooks...'
    rm -f .git/hooks/pre-commit
fi

# Remove old commit-msg hook if present
rm -f .git/hooks/commit-msg

# Install hk hooks with mise wrapper
# This creates: pre-commit, commit-msg (from hk.pkl)
hk install --mise

# Patch hooks to use absolute path to bin/mise (for GUI apps: Xcode, Fork, Tower)
# GUI apps don't inherit shell PATH, so we need absolute path
for hook in .git/hooks/pre-commit .git/hooks/commit-msg; do
    if [ -f "$hook" ] && grep -q "exec mise x" "$hook" 2>/dev/null; then
        sed -i '' "s|exec mise x|exec \"$PROJECT_ROOT/bin/mise\" x|g" "$hook"
        echo "  ✓ Patched $hook for GUI apps"
    fi
done

echo '✅ Git hooks configured successfully'
