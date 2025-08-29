#!/bin/bash

# VPC Module Update Validation Script
# Run this from the le-tf-infra-aws root directory

echo "🔍 Validating VPC Module Updates v3.19.0 across all environments"
echo "=================================================="

# Make sure we're on the correct branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "renovate/github.com-binbashar-terraform-aws-vpc-3.x" ]; then
    echo "❌ Not on the correct branch. Please run: git checkout renovate/github.com-binbashar-terraform-aws-vpc-3.x"
    exit 1
fi

echo "✅ On branch: $current_branch"
echo

# Activate leverage environment
source /Users/lgallard/git/binbash/activate-leverage.sh

# Array of directories to test
declare -a dirs=(
    "apps-devstg/us-east-1/base-network"
    "apps-devstg/us-east-1/k8s-eks-demoapps/network"
    "apps-prd/us-east-1/base-network"
    "network/us-east-1/base-network"
    "network/us-east-2/base-network"
    "security/us-east-1/base-network"
    "shared/us-east-1/base-network"
    "shared/us-east-2/base-network"
)

# Function to test each directory
test_directory() {
    local dir=$1
    echo "🧪 Testing: $dir"
    echo "------------------------"
    
    cd "$dir" || {
        echo "❌ Failed to change to directory: $dir"
        return 1
    }
    
    # Initialize with module upgrade first
    echo "🔄 Running terraform init -upgrade..."
    if leverage tf init -upgrade > /tmp/init_output_$(basename $dir).txt 2>&1; then
        echo "✅ Init successful"
    else
        echo "❌ Init failed - check /tmp/init_output_$(basename $dir).txt"
        cd - > /dev/null
        return 1
    fi
    
    # Run terraform plan and capture the result
    echo "📋 Running terraform plan..."
    if leverage tf plan > /tmp/plan_output_$(basename $dir).txt 2>&1; then
        echo "✅ Plan successful"
        
        # Check for breaking changes (should only see module updates)
        if grep -q "Plan: .* to add, .* to change, .* to destroy" /tmp/plan_output_$(basename $dir).txt; then
            plan_line=$(grep "Plan: " /tmp/plan_output_$(basename $dir).txt)
            echo "📊 $plan_line"
        else
            echo "📊 No changes detected (infrastructure up-to-date)"
        fi
        
        # Check for errors
        if grep -q "Error:" /tmp/plan_output_$(basename $dir).txt; then
            echo "⚠️  Errors found - check /tmp/plan_output_$(basename $dir).txt"
        fi
    else
        echo "❌ Plan failed - check /tmp/plan_output_$(basename $dir).txt"
    fi
    
    echo
    cd - > /dev/null
}

# Test all directories
for dir in "${dirs[@]}"; do
    test_directory "$dir"
done

echo "🎯 Validation Complete!"
echo "=================================================="
echo "📁 Detailed logs saved to:"
echo "   - Init logs: /tmp/init_output_*.txt"
echo "   - Plan logs: /tmp/plan_output_*.txt"
echo "🔄 Next step: Add 'atlantis plan' comment to PR #828"
echo
echo "Expected results:"
echo "✅ All inits should download new v3.19.0 modules successfully"
echo "✅ All plans should be successful"
echo "✅ Only module source updates (no resource changes)"
echo "✅ Some environments may show infrastructure drift (peering connections)"
echo "⚠️  This is normal and not related to the VPC module update"