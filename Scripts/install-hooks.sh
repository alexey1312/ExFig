#!/bin/bash
#
# Smart git hooks installer with version checking
# Only reinstalls if hooks are missing, outdated, or config changed
# Called from: environment.sh, mise run setup
#
# Version history:
#   1 - Initial hk migration from pre-commit framework
#   2 - Added smart version checking and config hash detection
#

set -e

# =============================================================================
# HOOKS INSTALLER VERSION - increment when install logic changes!
# =============================================================================
readonly HOOKS_VERSION="2"

# Get project root (parent of Scripts directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Quiet mode: only log when VERBOSE=1 or when action needed
log() { [[ "${VERBOSE:-}" == "1" ]] && echo "[hooks] $*" || true; }
log_action() { echo "[hooks] $*"; }  # Always show actions

# Resolve git directory (handles worktrees where .git is a file)
resolve_git_dirs() {
    if [ -f ".git" ]; then
        # This is a worktree - .git is a file containing "gitdir: <path>"
        GIT_DIR=$(cat .git | sed 's/^gitdir: //')
        # Resolve relative paths
        if [[ ! "$GIT_DIR" = /* ]]; then
            GIT_DIR="$PROJECT_ROOT/$GIT_DIR"
        fi
        # For worktrees, hooks are in the main repo's .git/hooks
        MAIN_GIT_DIR=$(dirname "$(dirname "$GIT_DIR")")
        HOOKS_DIR="$MAIN_GIT_DIR/hooks"
        MAIN_REPO_DIR=$(dirname "$MAIN_GIT_DIR")
        IS_WORKTREE=true
    else
        GIT_DIR="$PROJECT_ROOT/.git"
        HOOKS_DIR="$GIT_DIR/hooks"
        MAIN_REPO_DIR=""
        IS_WORKTREE=false
    fi
    MISE_PATH="${MAIN_REPO_DIR:-$PROJECT_ROOT}/bin/mise"
}

# Calculate config hash (for change detection)
get_config_hash() {
    local config_file="$PROJECT_ROOT/hk.pkl"
    if [ -f "$config_file" ]; then
        # Use md5 on macOS, md5sum on Linux
        if command -v md5 &>/dev/null; then
            md5 -q "$config_file"
        else
            md5sum "$config_file" | cut -d' ' -f1
        fi
    else
        echo "no-config"
    fi
}

# Parse stamp file: version|config_hash|timestamp
parse_stamp() {
    local stamp_file="$HOOKS_DIR/.hk-installed"
    if [ -f "$stamp_file" ]; then
        cat "$stamp_file"
    else
        echo "0|none|none"
    fi
}

# Check if hooks need installation/update
hooks_need_update() {
    local stamp_file="$HOOKS_DIR/.hk-installed"
    local current_hash
    local installed_version installed_hash

    # Check if required hooks exist
    for hook in pre-commit commit-msg; do
        if [ ! -f "$HOOKS_DIR/$hook" ]; then
            log "Hook missing: $hook"
            return 0
        fi
    done

    # Check if hooks have correct mise path (for GUI apps)
    if [ -f "$HOOKS_DIR/pre-commit" ] && ! grep -q "$MISE_PATH" "$HOOKS_DIR/pre-commit" 2>/dev/null; then
        log "Hooks need mise path update"
        return 0
    fi

    # Check if old pre-commit framework hooks exist (need migration)
    if [ -f "$HOOKS_DIR/pre-commit" ] && grep -q "pre-commit" "$HOOKS_DIR/pre-commit" 2>/dev/null && ! grep -q "hk" "$HOOKS_DIR/pre-commit" 2>/dev/null; then
        log "Old pre-commit framework detected, needs migration"
        return 0
    fi

    # Check stamp file exists
    if [ ! -f "$stamp_file" ]; then
        log "No installation stamp found"
        return 0
    fi

    # Parse installed version and hash
    IFS='|' read -r installed_version installed_hash _ < <(parse_stamp)

    # Check version mismatch
    if [ "$installed_version" != "$HOOKS_VERSION" ]; then
        log "Version mismatch: installed=$installed_version, current=$HOOKS_VERSION"
        return 0
    fi

    # Check config hash mismatch
    current_hash=$(get_config_hash)
    if [ "$installed_hash" != "$current_hash" ]; then
        log "Config changed: $installed_hash -> $current_hash"
        return 0
    fi

    return 1
}

install_hooks() {
    log_action "Installing git hooks (v$HOOKS_VERSION)..."

    # Ensure hooks directory exists
    mkdir -p "$HOOKS_DIR"

    # Remove old hooks
    rm -f "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/commit-msg"

    # Install hk hooks (quiet output)
    if [ "$IS_WORKTREE" = true ]; then
        log "Detected git worktree, installing from main repo"
        (cd "$MAIN_REPO_DIR" && hk install --mise) >/dev/null
    else
        hk install --mise >/dev/null
    fi

    # Patch hooks to use absolute mise path (for GUI apps: Xcode, Fork, Tower)
    for hook in "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/commit-msg"; do
        if [ -f "$hook" ] && grep -q "exec mise x" "$hook" 2>/dev/null; then
            sed -i.bak "s|exec mise x|exec \"$MISE_PATH\" x|g" "$hook" && rm -f "$hook.bak"
        fi
    done

    # Create installation stamp: version|config_hash|timestamp
    local config_hash timestamp
    config_hash=$(get_config_hash)
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "${HOOKS_VERSION}|${config_hash}|${timestamp}" > "$HOOKS_DIR/.hk-installed"

    log_action "✅ Git hooks installed (v$HOOKS_VERSION)"
}

show_status() {
    resolve_git_dirs

    local stamp_file="$HOOKS_DIR/.hk-installed"
    local installed_version installed_hash installed_time
    local current_hash

    echo "Git hooks status:"
    echo "  Hooks directory: $HOOKS_DIR"
    echo "  Current version: $HOOKS_VERSION"

    if [ -f "$stamp_file" ]; then
        IFS='|' read -r installed_version installed_hash installed_time < <(parse_stamp)
        echo "  Installed version: $installed_version"
        echo "  Installed at: $installed_time"
        echo "  Config hash: $installed_hash"

        current_hash=$(get_config_hash)
        if [ "$installed_version" != "$HOOKS_VERSION" ]; then
            echo "  ⚠️  Version mismatch! Run: ./Scripts/install-hooks.sh"
        elif [ "$installed_hash" != "$current_hash" ]; then
            echo "  ⚠️  Config changed! Run: ./Scripts/install-hooks.sh"
        else
            echo "  ✅ Up to date"
        fi
    else
        echo "  ❌ Not installed. Run: ./Scripts/install-hooks.sh"
    fi
}

main() {
    # Parse arguments
    case "${1:-}" in
        --status|-s)
            show_status
            return 0
            ;;
        --force|-f)
            resolve_git_dirs
            install_hooks
            return 0
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --status, -s    Show hooks installation status"
            echo "  --force, -f     Force reinstall hooks"
            echo "  --help, -h      Show this help"
            echo ""
            echo "Environment:"
            echo "  VERBOSE=1       Enable verbose logging"
            return 0
            ;;
    esac

    # Skip on CI - hooks are not needed there
    if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
        log "CI detected, skipping hooks installation"
        return 0
    fi

    resolve_git_dirs

    if hooks_need_update; then
        install_hooks
    else
        log "Hooks up to date"  # Silent when up to date
    fi
}

main "$@"
