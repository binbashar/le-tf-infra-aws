---
description: "Smart analysis of GitHub issues/PRs with auto-labeling, assignment, and conditional Terraform validation"
allowed-tools: ["Task", "mcp__github-server__get_issue", "mcp__github-server__get_pull_request", "mcp__github-server__update_issue", "mcp__github-server__list_issues", "mcp__github-server__search_issues", "mcp__github-server__add_issue_comment", "mcp__obsidian__search_notes", "mcp__obsidian__read_notes", "Bash"]
---

# GitHub Issue Chore Dependencies

Advanced analysis of GitHub issues and PRs with smart decision-tree workflow. Prevents unnecessary Terraform plan validations by using explicit dependency breaking change detection.

This command follows a 7-step intelligent workflow:
1. **Initial Analysis** - Parse issue number, construct URL, analyze dependency update
2. **Smart Labeling** - Auto-suggest labels based on similar closed issues and patterns
3. **Assignment Management** - Auto-detect or prompt for assignee
4. **Breaking Change Assessment** - Only flag dependency/module breaking changes that affect infrastructure
5. **Confirmation Gate** - Require explicit approval before tf plan validation
6. **Terraform Validation** - Only after explicit user confirmation
7. **Reporting** - Add comprehensive report + request @coderabbitai review

Usage: `/gh-issue-chore-deps <issue-number> [--labels label1,label2] [--assignee username]`

Examples:
- `/gh-issue-chore-deps 892`
- `/gh-issue-chore-deps 834 --labels dependencies,patch`
- `/gh-issue-chore-deps 892 --assignee lgallard`
- `/gh-issue-chore-deps 834 --labels dependencies --assignee exequielbarrirero`

**Key Features:**
- ✅ Smart labeling based on repository patterns and similar issues
- ✅ Automatic assignment detection and management
- ✅ Intelligent decision-tree prevents unnecessary tf plan runs
- ✅ Explicit confirmation gates before infrastructure validation
- ✅ Integration with CodeRabbit AI analysis and GitHub management
- ✅ Mandatory comprehensive reporting with @coderabbitai review
- ⚠️  Only runs tf plans for actual dependency breaking changes affecting infrastructure
- 🎯 Hardcoded for binbashar/le-tf-infra-aws repository
- 🔍 Understands layers with "--" suffix are special cases (rarely deployed)

# Parse arguments
ISSUE_NUMBER="${1}"
CUSTOM_LABELS=""
CUSTOM_ASSIGNEE=""

# Parse optional arguments
shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --labels)
      CUSTOM_LABELS="$2"
      shift 2
      ;;
    --assignee)
      CUSTOM_ASSIGNEE="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [ -z "$ISSUE_NUMBER" ]; then
  echo "❌ Usage: /gh-issue-chore-deps <issue-number> [--labels label1,label2] [--assignee username]"
  echo "   Examples:"
  echo "   /gh-issue-chore-deps 892"
  echo "   /gh-issue-chore-deps 834 --labels dependencies,patch"
  echo "   /gh-issue-chore-deps 892 --assignee lgallard"
  exit 1
fi

# Validate issue number format
if ! [[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "❌ Invalid issue number format: $ISSUE_NUMBER"
  echo "   Expected: numeric value (e.g., 892, 834)"
  exit 1
fi

# Hardcoded repository info for binbashar/le-tf-infra-aws
OWNER="binbashar"
REPO="le-tf-infra-aws"

# Validate we have gh CLI
if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh) is required but not found"
  echo "   Install: https://cli.github.com/"
  exit 1
fi

# Validate repository access
if ! gh repo view "$OWNER/$REPO" &> /dev/null; then
  echo "❌ Cannot access repository $OWNER/$REPO"
  echo "   Check if you have proper authentication and access rights"
  exit 1
fi

echo "✅ Repository access confirmed"
echo "🔍 Detecting if #$ISSUE_NUMBER is an issue or PR..."
if gh pr view "$ISSUE_NUMBER" --repo "$OWNER/$REPO" &> /dev/null; then
  ISSUE_TYPE="pull"
  ISSUE_URL="https://github.com/$OWNER/$REPO/pull/$ISSUE_NUMBER"
elif gh issue view "$ISSUE_NUMBER" --repo "$OWNER/$REPO" &> /dev/null; then
  ISSUE_TYPE="issue"
  ISSUE_URL="https://github.com/$OWNER/$REPO/issues/$ISSUE_NUMBER"
else
  echo "❌ Issue/PR #$ISSUE_NUMBER not found in $OWNER/$REPO"
  echo "   Please verify the number exists and you have access"
  exit 1
fi

echo "🚀 GitHub Issue Chore Dependencies"
echo "📋 Analyzing: $OWNER/$REPO #$ISSUE_NUMBER"
echo "📂 Type: $(echo $ISSUE_TYPE | tr '[:lower:]' '[:upper:]')"
echo "🔗 URL: $ISSUE_URL"
if [ -n "$CUSTOM_LABELS" ]; then
  echo "🏷️  Custom labels: $CUSTOM_LABELS"
fi
if [ -n "$CUSTOM_ASSIGNEE" ]; then
  echo "👤 Custom assignee: $CUSTOM_ASSIGNEE"
fi
echo ""
echo "🔄 Initiating comprehensive dependency analysis..."
echo ""

# Initiate the improved analysis workflow using Task tool
Using the defined Claude Code subagents in the repo, make sure to:

1. **Initial Analysis**
   - Analyze the issue reported by Renovate/Dependabot/etc.
   - Review CodeRabbitAI analysis if available
   - Identify the type of update (dependency version, Terraform provider, module, etc.)

2. **Smart Labeling and Assignment**
   - IF custom labels provided: Use them
   - ELSE: Analyze similar closed issues to suggest appropriate labels
   - Common patterns to detect:
     * `dependencies` - Renovate/Dependabot PRs
     * `security` - Security-related updates
     * `enhancement` - Feature additions/improvements
     * `patch` - Version bumps and fixes
   - IF custom assignee provided: Use them
   - ELSE: Try to detect assignee from GitHub context or prompt user
   - Apply labels and assignee using mcp__github-server__update_issue

3. **Breaking Change Assessment** (Focus on Dependency Breaking Changes)
   - ONLY consider these as potential infrastructure-affecting dependency changes:
     * Terraform/OpenTofu provider major version updates with breaking changes
     * Terraform module updates that modify resource schemas or APIs
     * Infrastructure dependencies with breaking changes (AWS SDK major versions, Kubernetes clients, etc.)
     * Dependency updates affecting Terraform state compatibility or resource definitions
   - **EXCLUDE from tf plan validation:**
     * Minor/patch version dependency updates
     * Development-only dependencies
     * Language runtime updates without infrastructure impact
     * Linting/testing tool updates
     * Documentation-only updates
   - **Special consideration for layers ending with "--" suffix:**
     * These are special-case layers rarely deployed/tested
     * Even lower threshold for triggering tf plan validation
     * Focus on widely-used layers like base-network, base-tf-backend, etc.

4. **Confirmation Gate**
   - IF dependency breaking changes are detected:
     * Ask for explicit confirmation: "Dependency breaking changes detected. Do you want me to run tf plan validation?"
     * Wait for user confirmation before proceeding
   - IF no dependency breaking changes: SKIP tf plan validation entirely

5. **Terraform Validation** (ONLY after user confirmation)
   - Activate leverage CLI and AWS SSO auth
   - Run tf plans using files updated in the PR (prioritize commonly deployed layers)
   - Add comprehensive report table to the issue

6. **Mandatory Reporting and Review**
   - ALWAYS add comprehensive analysis report as comment to the issue/PR
   - Include: dependency analysis, labeling decisions, terraform validation results (if any)
   - ALWAYS request @coderabbitai review of the PR and analysis
   - Format: "@coderabbitai please review this dependency update and my analysis"

Let's analyze $OWNER/$REPO#$ISSUE_NUMBER dependency update

echo "📊 Dependency analysis workflow initiated - check Claude Code output above for detailed results"