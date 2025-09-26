#!/bin/bash

# Claude Code GitHub Action Setup Script
# This script helps configure the necessary secrets for Claude Code GitHub Action

set -e

echo "🤖 Claude Code GitHub Action Setup"
echo "=================================="
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "   Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is logged in
if ! gh auth status &> /dev/null; then
    echo "❌ Please log in to GitHub CLI first:"
    echo "   gh auth login"
    exit 1
fi

# Get repository information
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "📁 Repository: $REPO"
echo ""

# Check if ANTHROPIC_API_KEY secret exists
echo "🔍 Checking for ANTHROPIC_API_KEY secret..."
if gh secret list | grep -q "ANTHROPIC_API_KEY"; then
    echo "✅ ANTHROPIC_API_KEY secret already exists"
    echo ""
    echo "🎯 Setup is complete! The Claude Code GitHub Action should work."
    echo ""
    echo "Next steps:"
    echo "1. Create a PR or issue"
    echo "2. Comment with @claude followed by your question"
    echo "3. Watch Claude provide intelligent assistance!"
    echo ""
    echo "Example: @claude review this terraform configuration for security best practices"
else
    echo "❌ ANTHROPIC_API_KEY secret not found"
    echo ""
    echo "To complete the setup:"
    echo ""
    echo "1. Get your Anthropic API key:"
    echo "   - Visit: https://console.anthropic.com/"
    echo "   - Create an account or log in"
    echo "   - Navigate to API Keys section"
    echo "   - Create a new API key"
    echo ""
    echo "2. Add the secret to this repository:"
    echo "   gh secret set ANTHROPIC_API_KEY"
    echo ""
    echo "3. When prompted, paste your API key"
    echo ""
    echo "4. Test the action by mentioning @claude in a PR or issue"
    echo ""
    echo "Security note: API keys are stored securely in GitHub secrets"
    echo "and are never exposed in logs or to unauthorized users."
fi

echo ""
echo "📚 For detailed usage instructions, see:"
echo "   .github/CLAUDE_CODE_SETUP.md"
echo ""
echo "🔗 Claude Code Documentation:"
echo "   https://docs.claude.com/en/docs/claude-code/github-actions"