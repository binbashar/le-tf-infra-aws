#!/bin/bash
# Run Validation Strategies Script
# Multi-strategy validation with enhanced fallback mechanisms

set -euo pipefail

# Initialize validation results
VALIDATION_RESULTS=""
VALIDATION_STATUS="success"

# Enhanced function with strategy-based validation and fallbacks
run_validation() {
    local base_cmd="$1"
    local description="$2"
    local strategy="${VALIDATION_STRATEGY:-default}"

    echo "⚡ Running: $description (Strategy: $strategy)"

    # Ensure virtual environment is active for each command
    source ~/.leverage-venv/bin/activate

    # Get environment variables
    local CURRENT_DIR=$(pwd)
    local LEVERAGE_GITCONFIG="${LEVERAGE_GITCONFIG:-$HOME/.gitconfig}"
    local LEVERAGE_SSH_DIR="${LEVERAGE_SSH_DIR:-$HOME/.ssh}"
    local LEVERAGE_AWS_DIR="${LEVERAGE_AWS_DIR:-$HOME/.aws}"

    # Build command based on strategy - simplified for Leverage CLI 2.1.1 compatibility
    local cmd=""
    case "$strategy" in
        "leverage_standard"|"explicit_mounts"|"simplified_mounts"|"default")
            echo "🎯 Using standard Leverage CLI strategy (v2.1.1 compatible)"
            # Use standard leverage commands - the Docker mount configuration is handled by Leverage CLI automatically
            cmd="$base_cmd"
            ;;
        "direct_terraform")
            echo "🎯 Using direct terraform strategy (fallback)"
            if [[ "$base_cmd" == *"leverage"* ]]; then
                # Convert leverage command to direct terraform
                local tf_subcmd=$(echo "$base_cmd" | sed 's/.*leverage[^a-z]*tf[^a-z]*//')
                cmd="terraform $tf_subcmd"
            else
                cmd="$base_cmd"
            fi
            ;;
        *)
            echo "🎯 Using default Leverage CLI strategy"
            cmd="$base_cmd"
            ;;
    esac

    echo "Executing command: $cmd"

    # Try primary strategy
    if output=$(timeout 300 $cmd 2>&1); then
        echo "✅ $description: PASSED"
        VALIDATION_RESULTS="${VALIDATION_RESULTS}## $description\n✅ **PASSED** (Strategy: $strategy)\n\`\`\`\n${output}\n\`\`\`\n\n"
        return 0
    else
        echo "❌ $description: FAILED with $strategy strategy"
        echo "Failed output: $output"

        # Enhanced debugging and fallback attempts
        echo "🔧 Enhanced debugging and fallback attempts..."

        # Additional debugging for failed commands
        echo "🔍 Debugging failed command: $cmd"
        echo "Current strategy: $strategy"
        echo "Current directory: $(pwd)"
        echo "Working directory contents: $(ls -la)"
        echo "Environment variables:"
        env | grep -E "(DOCKER|LEVERAGE|VIRTUAL|PATH|VALIDATION)" | head -15

        # Attempt fallback strategies if primary failed
        if [[ "$strategy" != "direct_terraform" ]] && command -v terraform >/dev/null 2>&1; then
            echo "🔄 Attempting direct terraform fallback..."
            if [[ "$base_cmd" == *"leverage"* ]]; then
                local tf_subcmd=$(echo "$base_cmd" | sed 's/.*leverage[^a-z]*tf[^a-z]*//')
                local fallback_cmd="terraform $tf_subcmd"
                echo "Fallback command: $fallback_cmd"

                if fallback_output=$(timeout 300 $fallback_cmd 2>&1); then
                    echo "✅ $description: PASSED with direct terraform fallback"
                    VALIDATION_RESULTS="${VALIDATION_RESULTS}## $description\n✅ **PASSED** (Fallback: direct terraform)\n\`\`\`\n${fallback_output}\n\`\`\`\n\n"
                    return 0
                else
                    echo "❌ Direct terraform fallback also failed"
                    echo "Fallback output: $fallback_output"
                fi
            fi
        fi

        # Additional fallback: try with basic Leverage CLI command (no mount options)
        if [[ "$strategy" != "default" ]] && [[ "$base_cmd" == *"leverage"* ]]; then
            echo "🔄 Attempting basic Leverage CLI fallback..."
            echo "Basic fallback command: $base_cmd"

            if basic_output=$(timeout 300 $base_cmd 2>&1); then
                echo "✅ $description: PASSED with basic Leverage CLI fallback"
                VALIDATION_RESULTS="${VALIDATION_RESULTS}## $description\n✅ **PASSED** (Fallback: basic Leverage CLI)\n\`\`\`\n${basic_output}\n\`\`\`\n\n"
                return 0
            else
                echo "❌ Basic Leverage CLI fallback also failed"
                echo "Basic fallback output: $basic_output"
            fi
        fi

        # Record final failure with all attempted strategies
        VALIDATION_RESULTS="${VALIDATION_RESULTS}## $description\n❌ **FAILED** (Tried: $strategy, fallbacks attempted)\n\`\`\`\nPrimary output:\n${output}\n\`\`\`\n\n"
        VALIDATION_STATUS="failed"

        echo "❌ All strategies failed for: $description"
        return 1
    fi
}

# Export the function and variables for use in other scripts
export -f run_validation
export VALIDATION_RESULTS
export VALIDATION_STATUS

echo "✅ Validation strategies loaded and ready"