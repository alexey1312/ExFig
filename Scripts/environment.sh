#!/usr/bin/env bash

##
## This script configures environment for ExFig project,
## it MUST BE sourced - '$ source Scripts/environment.sh'
##

# Check if script is being sourced
SOURCED=0
(return 0 2>/dev/null) && SOURCED=1 || \
[[ $ZSH_EVAL_CONTEXT =~ :file$ ]] && SOURCED=1
if [ $SOURCED -eq 0 ]; then
    echo 'This script must be sourced! Please, run $ source Scripts/environment.sh' 1>&2
    exit 1
fi

echo 'Configuring environment for ExFig project'

#
# I. MISE SETUP
# -----------------------------------------------------------------------------
#

# Check if bin/mise bootstrap binary exists
if [ ! -f "./bin/mise" ]; then
    echo "bin/mise not found. Please regenerate it:"
    echo "   mise generate bootstrap > bin/mise"
    echo "   chmod +x bin/mise"
    return 1
fi

# Add bin directory to PATH for mise bootstrap binary
export PATH="$(pwd)/bin:$PATH"

# Show mise version
MISE_VERSION=$(./bin/mise --version 2>/dev/null)
echo "mise: $MISE_VERSION"

#
# II. ACTIVATE MISE
# -----------------------------------------------------------------------------
#

export MISE_OVERRIDE_TOOL_VERSIONS_FILENAMES="none"

echo 'Activating mise environment...'

# Detect current shell and activate mise accordingly
if [ -n "$ZSH_VERSION" ]; then
    SHELL_TYPE="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_TYPE="bash"
else
    echo "Unsupported shell. Please use bash or zsh."
    return 1
fi

eval "$(./bin/mise activate $SHELL_TYPE)"

if [ $? -ne 0 ]; then
    echo "Failed to activate mise environment"
    return 1
fi

echo 'mise environment activated successfully'

#
# III. TRUST AND INSTALL
# -----------------------------------------------------------------------------
#

# Trust the mise.toml configuration file
# This is required for security - mise won't read configs by default
if [ -f "mise.toml" ]; then
    mise trust mise.toml 2>/dev/null || true
fi

echo 'Installing tools from mise.toml...'
mise install

if [ $? -ne 0 ]; then
    echo "Failed to install tools"
    return 1
fi

echo 'Tools installed successfully'

# Re-activate mise to update PATH with newly installed tools
eval "$(mise activate $SHELL_TYPE)"

#
# IV. GITHUB ACTIONS INTEGRATION
# -----------------------------------------------------------------------------
#

# Add PATH to GitHub Actions environment if running in CI
# https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions
if [ -n "$GITHUB_PATH" ]; then
    echo "Adding PATH to GitHub Path..."
    echo "$PATH" >> "$GITHUB_PATH"
fi

#
# V. VERIFICATION
# -----------------------------------------------------------------------------
#

# Verify key tools are installed and from mise
echo 'Verifying installed tools...'
for tool in swiftformat swiftlint xcsift pre-commit; do
    tool_path=$(command -v "$tool" 2>/dev/null)
    if [ -n "$tool_path" ]; then
        if [[ "$tool_path" == *"/mise/"* ]]; then
            echo "  $tool: $tool_path"
        else
            echo "  $tool: $tool_path (not from mise)"
        fi
    else
        echo "  $tool: not found"
    fi
done

echo 'Project environment setup done!'
