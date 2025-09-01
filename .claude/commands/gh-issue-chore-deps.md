---
description: "Agentic dependency analysis using specialized dependency-update agent with mirrored module support"
allowed-tools: ["Task", "Bash"]
---

# GitHub Issue Chore Dependencies (Optimized)

Agentic analysis of dependency update issues/PRs using the specialized `dependency-update` agent. Handles mirrored modules by checking upstream repositories and provides fully autonomous workflow.

**Key Improvements:**
- 🤖 **Fully Agentic**: Uses specialized `dependency-update` agent for autonomous analysis
- 🔍 **Mirrored Module Support**: Detects and checks upstream repositories for changelog/dependencies  
- 📊 **MCP Integration**: Leverages terraform MCP servers for provider documentation
- ⚡ **Token Optimized**: ~70% reduction in token usage through specialized agent
- 🎯 **Smart Validation**: Intelligent terraform plan execution only when needed

Usage: `/gh-issue-chore-deps <issue-number> [--labels label1,label2] [--assignee username]`

Examples:
- `/gh-issue-chore-deps 892`
- `/gh-issue-chore-deps 834 --labels dependencies,patch`  
- `/gh-issue-chore-deps 892 --assignee lgallard`

# Streamlined argument parsing and validation
ISSUE_NUMBER="${1}"
CUSTOM_LABELS="${2:-}"
CUSTOM_ASSIGNEE="${3:-}"

# Parse optional arguments  
shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --labels) CUSTOM_LABELS="$2"; shift 2 ;;
    --assignee) CUSTOM_ASSIGNEE="$2"; shift 2 ;;
    *) echo "❌ Unknown argument: $1"; exit 1 ;;
  esac
done

# Basic validation
if [ -z "$ISSUE_NUMBER" ] || ! [[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "❌ Usage: /gh-issue-chore-deps <issue-number> [--labels label1,label2] [--assignee username]"
  exit 1
fi

echo "🤖 Delegating to dependency-update agent for issue #${ISSUE_NUMBER}..."

# ===================================================================================
# CLAUDE: MANDATORY - Use the Task tool with subagent_type="dependency-update"
# ===================================================================================
# 
# You MUST execute the Task tool with the following exact parameters:
# - description: "Dependency analysis for issue #${ISSUE_NUMBER}"
# - subagent_type: "dependency-update" 
# - prompt: [The detailed prompt below]
#
# DO NOT analyze the issue yourself - ALWAYS delegate to the dependency-update agent
# ===================================================================================

echo "🚀 Launching dependency-update agent for autonomous analysis..."

Analyze binbashar/le-tf-infra-aws#${ISSUE_NUMBER} with the following enhanced capabilities:

**MIRRORED MODULE HANDLING (INTERNAL ANALYSIS ONLY):**
- For any module updates, check if the source repository is a GitHub mirror/fork
- If mirrored, identify and check the upstream/original repository for:
  - Changelog and release notes not available in mirror
  - Dependency update details and breaking changes
  - Security advisories and migration guides
- Use GitHub API to trace fork relationships and find original repositories
- **IMPORTANT**: Use this information for INTERNAL analysis only - DO NOT mention fork/mirror relationships in public GitHub comments

**ENHANCED ANALYSIS WORKFLOW:**
1. **Repository Context**: Analyze issue/PR in binbashar/le-tf-infra-aws context
2. **Dependency Detection**: Identify Renovate/Dependabot updates and affected modules/providers
3. **Upstream Checking**: For mirrored modules, fetch upstream repository information
4. **Smart Labeling**: Apply labels (custom: "${CUSTOM_LABELS}" or auto-detected)
5. **Assignment**: Handle assignee (custom: "${CUSTOM_ASSIGNEE}" or auto-detect)
6. **Breaking Change Assessment**: Use MCP terraform servers for provider documentation
7. **Validation Decision**: Intelligently determine if terraform plan validation is needed
   - **SKIP terraform validation when ALL conditions met:**
     * ALL affected layers end with "--" suffix (rarely deployed special cases)
     * AND update is patch/minor version (not major)  
     * AND no important changes reported (only routine dependency updates, bug fixes, etc.)
   - **RECOMMEND terraform validation when ANY condition met:**
     * At least one commonly deployed layer (without "--" suffix) is affected
     * OR major version update with potential breaking changes
     * OR important changes detected (security fixes, API changes, new features, etc.)
8. **Comprehensive Reporting**: Add detailed comment with @coderabbitai review request

**MCP INTEGRATION:**
- Use terraform MCP servers for provider/module documentation
- Leverage GitHub MCP tools for repository analysis
- Apply sequential thinking for complex dependency chains

**OUTPUT REQUIREMENTS:**
- Complete autonomous analysis without user intervention
- Detailed report as GitHub comment on the issue/PR
- Smart terraform validation only when infrastructure-impacting changes detected

**REPORT FORMATTING REQUIREMENTS:**
- **Impact Assessment**: List actual affected infrastructure components (files, layers, services) - never use empty numbered lists
- **Labels Applied**: Show clear before/after context, e.g. "Applied labels: dependencies, patch (enhancement was already present)"
- **Upstream Information**: Keep internal - do not mention fork/mirror relationships in public comments
- **Infrastructure Analysis**: Provide specific file paths and affected components, not placeholder text
- **Quality Control**: Ensure all sections contain actual data, not empty placeholders

echo "✅ Claude will now execute the Task tool with dependency-update agent automatically"