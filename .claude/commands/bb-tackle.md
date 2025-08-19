---
description: "Smart analysis of GitHub issues/PRs with auto-labeling, assignment, and conditional Terraform validation"
allowed-tools: ["Task", "mcp__github-server__get_issue", "mcp__github-server__get_pull_request", "mcp__github-server__update_issue", "mcp__github-server__list_issues", "mcp__github-server__search_issues", "mcp__github-server__add_issue_comment", "mcp__obsidian__search_notes", "mcp__obsidian__read_notes", "Bash"]
---

# Binbash Issue Tackler

Advanced analysis of GitHub issues and PRs with smart decision-tree workflow. Prevents unnecessary Terraform plan validations by using explicit breaking change detection.

This command follows a 6-step intelligent workflow:
1. **Initial Analysis** - Analyze issue/PR content and context
2. **Smart Labeling** - Auto-suggest labels based on similar closed issues and patterns
3. **Assignment Management** - Auto-detect or prompt for assignee
4. **Breaking Change Assessment** - Only flag infrastructure-affecting changes
5. **Confirmation Gate** - Require explicit approval before tf plan validation
6. **Documentation** - Create Obsidian notes with time investment analysis

Usage: `/bb-tackle <github-issue-url> [--labels label1,label2] [--assignee username]`

Examples:
- `/bb-tackle https://github.com/binbashar/le-tf-infra-aws/pull/834`
- `/bb-tackle https://github.com/binbashar/leverage/issues/456 --labels security,patch`
- `/bb-tackle https://github.com/binbashar/le-tf-infra-aws/pull/834 --assignee lgallard`
- `/bb-tackle https://github.com/binbashar/le-tf-infra-aws/pull/834 --labels dependencies --assignee exequielbarrirero`

**Key Features:**
- ✅ Smart labeling based on repository patterns and similar issues
- ✅ Automatic assignment detection and management
- ✅ Intelligent decision-tree prevents unnecessary tf plan runs
- ✅ Explicit confirmation gates before infrastructure validation
- ✅ Integration with CodeRabbit AI analysis and GitHub management
- ✅ Automatic Obsidian documentation with time tracking
- ⚠️  Only runs tf plans for actual infrastructure-affecting changes

# Parse arguments
ISSUE_URL="${1}"
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

if [ -z "$ISSUE_URL" ]; then
  echo "❌ Usage: /bb-tackle <github-issue-url> [--labels label1,label2] [--assignee username]"
  echo "   Examples:"
  echo "   /bb-tackle https://github.com/binbashar/le-tf-infra-aws/pull/834"
  echo "   /bb-tackle https://github.com/binbashar/le-tf-infra-aws/pull/834 --labels dependencies,patch"
  echo "   /bb-tackle https://github.com/binbashar/le-tf-infra-aws/pull/834 --assignee lgallard"
  exit 1
fi

# Extract repo info from URL
REPO_PATTERN="github\.com/([^/]+)/([^/]+)/(issues|pull)/([0-9]+)"

if [[ $ISSUE_URL =~ $REPO_PATTERN ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  ISSUE_TYPE="${BASH_REMATCH[3]}"
  ISSUE_NUMBER="${BASH_REMATCH[4]}"
else
  echo "❌ Invalid GitHub URL format"
  echo "   Expected: https://github.com/owner/repo/issues/123 or https://github.com/owner/repo/pull/123"
  exit 1
fi

echo "🚀 Binbash Issue Tackler"
echo "📋 Analyzing: $OWNER/$REPO #$ISSUE_NUMBER"
echo "📂 Type: $(echo $ISSUE_TYPE | tr '[:lower:]' '[:upper:]')"
if [ -n "$CUSTOM_LABELS" ]; then
  echo "🏷️  Custom labels: $CUSTOM_LABELS"
fi
if [ -n "$CUSTOM_ASSIGNEE" ]; then
  echo "👤 Custom assignee: $CUSTOM_ASSIGNEE"
fi
echo ""

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
echo "🔄 Initiating comprehensive analysis..."
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

3. **Breaking Change Assessment**
   - ONLY consider these as potential infrastructure-affecting changes:
     * Terraform provider major version updates
     * Terraform module updates that modify resource schemas
     * Updates to infrastructure-related dependencies (AWS SDK, Kubernetes clients, etc.)
     * Changes affecting Terraform state or resource definitions
   - **EXCLUDE from tf plan validation:**
     * Minor/patch version updates
     * Development dependencies
     * Language runtime updates
     * Linting/testing tool updates
     * Documentation updates

4. **Confirmation Gate**
   - IF infrastructure-affecting changes are detected:
     * Ask for explicit confirmation: "Infrastructure changes detected. Do you want me to run tf plan validation?"
     * Wait for user confirmation before proceeding
   - IF no infrastructure changes: SKIP tf plan validation entirely

5. **Terraform Validation** (ONLY after user confirmation)
   - Activate leverage CLI and AWS SSO auth
   - Run tf plans using files updated in the PR
   - Add report table to the issue

6. **Final Steps**
   - Ask CodeRabbitAI to validate the PR and analysis
   - Create Obsidian document in /Users/lgallard/Library/Mobile Documents/iCloud~md~obsidian/Documents/second_brain/Binbash/
   - Include Time Investment Analysis with TOTAL ACTIVE WORKING TIME
   - Include #$ISSUE_NUMBER in note title

Let's tackle $OWNER/$REPO#$ISSUE_NUMBER

echo "📊 Analysis workflow initiated - check Claude Code output above for detailed results"