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

    # Build command based on strategy
    local cmd=""
    case "$strategy" in
        "explicit_mounts")
            echo "🎯 Using explicit mount control strategy"
            if [[ "$base_cmd" == *"leverage"* ]]; then
                # Replace leverage command with explicit mount version
                local tf_subcmd=$(echo "$base_cmd" | sed 's/.*leverage[^a-z]*tf[^a-z]*//')
                cmd="leverage --mount \"$CURRENT_DIR\" \"/workspace\" --mount \"$LEVERAGE_GITCONFIG\" \"/home/leverage/.gitconfig\" --mount \"$LEVERAGE_SSH_DIR\" \"/home/leverage/.ssh\" --mount \"$LEVERAGE_AWS_DIR\" \"/home/leverage/.aws\" --env-var \"AWS_ACCESS_KEY_ID\" \"$AWS_ACCESS_KEY_ID\" --env-var \"AWS_SECRET_ACCESS_KEY\" \"$AWS_SECRET_ACCESS_KEY\" --env-var \"AWS_DEFAULT_REGION\" \"$AWS_DEFAULT_REGION\" --verbose tf $tf_subcmd"
            else
                cmd="$base_cmd"
            fi
            ;;
        "simplified_mounts")
            echo "🎯 Using simplified mount strategy"
            if [[ "$base_cmd" == *"leverage"* ]]; then
                local tf_subcmd=$(echo "$base_cmd" | sed 's/.*leverage[^a-z]*tf[^a-z]*//')
                cmd="leverage --mount \"$CURRENT_DIR\" \"/workspace\" --env-var \"AWS_DEFAULT_REGION\" \"$AWS_DEFAULT_REGION\" --verbose tf $tf_subcmd"
            else
                cmd="$base_cmd"
            fi
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
            echo "🎯 Using default strategy"
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

        # If simplified strategy didn't work, try with minimal mounts
        if [[ "$strategy" != "simplified_mounts" ]] && [[ "$base_cmd" == *"leverage"* ]]; then
            echo "🔄 Attempting simplified mount fallback..."
            local tf_subcmd=$(echo "$base_cmd" | sed 's/.*leverage[^a-z]*tf[^a-z]*//')
            local simplified_cmd="leverage --mount \"$CURRENT_DIR\" \"/workspace\" --verbose tf $tf_subcmd"
            echo "Simplified fallback command: $simplified_cmd"

            if simplified_output=$(timeout 300 $simplified_cmd 2>&1); then
                echo "✅ $description: PASSED with simplified mount fallback"
                VALIDATION_RESULTS="${VALIDATION_RESULTS}## $description\n✅ **PASSED** (Fallback: simplified mounts)\n\`\`\`\n${simplified_output}\n\`\`\`\n\n"
                return 0
            else
                echo "❌ Simplified mount fallback also failed"
                echo "Simplified fallback output: $simplified_output"
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