---
description: "Intelligently save current session progress to Obsidian notes for seamless continuation"
allowed-tools: ["Bash", "mcp__obsidian__search_notes", "mcp__obsidian__read_notes"]
---

# Save Session Progress

Agentic session progress tracking that saves current work context to structured Obsidian notes. Eliminates context overload when starting new sessions by preserving progress, findings, and next steps.

**Key Features:**
- 🤖 **Fully Autonomous**: Intelligent analysis of current session context
- 📊 **Git Integration**: Auto-extracts branch, commits, and file changes
- 🔍 **Smart Detection**: Identifies issue/PR numbers from branch names
- 📝 **Structured Notes**: Creates comprehensive, actionable session documentation
- 🔄 **Update Support**: Handles existing note updates vs new note creation
- 🎯 **Next Steps**: Generates actionable checklist for future sessions

Usage: `/save-session [summary] [--type session-type] [--update]`

Examples:
- `/save-session` - Auto-analyze and save current session
- `/save-session "Fixed KMS layer compatibility issues"` - Add custom summary
- `/save-session --type bug-fix` - Categorize session type
- `/save-session --update` - Force update existing note for today

# Enhanced argument parsing and validation
CUSTOM_SUMMARY="${1:-}"
SESSION_TYPE="${2:-}"
FORCE_UPDATE="${3:-}"

# Parse optional arguments
shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --type) SESSION_TYPE="$2"; shift 2 ;;
    --update) FORCE_UPDATE="true"; shift ;;
    --summary) CUSTOM_SUMMARY="$2"; shift 2 ;;
    *)
      # If no flag, treat as summary
      if [[ -z "$CUSTOM_SUMMARY" ]] && [[ ! "$1" =~ ^-- ]]; then
        CUSTOM_SUMMARY="$1"
      else
        echo "❌ Unknown argument: $1"
        echo "Usage: /save-session [summary] [--type session-type] [--update]"
        exit 1
      fi
      shift
      ;;
  esac
done

echo "🤖 Analyzing current session and saving progress to Obsidian..."

# ===================================================================================
# CLAUDE: MANDATORY - Autonomous Session Analysis and Obsidian Note Creation
# ===================================================================================
#
# You MUST perform the following comprehensive session analysis and note creation:
#
# 1. CONTEXT EXTRACTION:
#    - Use Bash tools to extract git context: current branch, recent commits (last 5), git status
#    - Extract worktree context: git worktree list, git rev-parse --show-toplevel, worktree path
#    - Analyze current working directory and identify recent file modifications
#    - Extract issue/PR numbers from branch names using regex patterns
#    - Determine session duration if possible from git log timestamps
#    - Capture Claude Code working context: pwd, recent tool usage, active file patterns
#    - Extract TodoWrite states and active task progression
#    - Detect worktree vs main repository context for proper session naming
#
# 2. OBSIDIAN INTEGRATION:
#    - Use mcp__obsidian__search_notes to find existing session notes for today
#    - Path pattern: "second_brain/Binbash/sessions"
#    - Search for notes matching today's date pattern: "YYYY-MM-DD"
#
# 3. INTELLIGENT NOTE CREATION:
#    - Generate worktree-aware note title: "{YYYY-MM-DD} - {branch-name} - {worktree-context} - Session Notes"
#    - Check for existing sessions with same date/branch/worktree combination
#    - If collision detected, append timestamp: "{YYYY-MM-DD-HH:MM} - {branch-name} - {worktree-context} - Session Notes"
#    - If FORCE_UPDATE="true" or existing note found, update existing content
#    - Otherwise, create new note with structured markdown template
#    - Handle both worktree and main repository contexts appropriately
#
# 4. NOTE STRUCTURE (Markdown Template):
#    ```markdown
#    # {Date} - {Branch/Issue} - Session Notes
#
#    ## Session Overview
#    - **Date**: {Current date and time}
#    - **Branch**: {Current git branch}
#    - **Worktree**: {worktree path or 'main repository'}
#    - **Directory**: {full working directory path}
#    - **Issue/PR**: {Extracted from branch name or "N/A"}
#    - **Type**: {SESSION_TYPE or auto-detected from branch/commits}
#    - **Duration**: {Estimated from git activity}
#
#    ## Worktree Context
#    - **Repository Root**: {git rev-parse --show-toplevel}
#    - **Worktree Path**: {current worktree location or 'main repository'}
#    - **Parent Repository**: {main repo path if worktree detected}
#    - **Worktree Branch**: {branch associated with this worktree}
#    - **Full Directory Path**: {complete pwd output for precise restoration}
#
#    ## Context & Objectives
#    {Auto-extracted from branch name, recent commits, working directory context}
#
#    ## Progress Made
#    {Analysis of recent commits, file changes, resolved issues}
#
#    ## Issues & Blockers
#    {Any error states, failed tests, blocking dependencies found}
#
#    ## Claude Code Context
#    ### Recent Tool Usage
#    - **Read**: {Files examined with key findings}
#    - **Edit**: {Files modified with change summaries}
#    - **Bash**: {Commands executed with outcomes}
#    - **Grep/Glob**: {Search patterns used and results}
#    - **MCP Tools**: {Recent server interactions and results}
#
#    ### Active Workspace
#    - **Working Directory**: {Current pwd output}
#    - **Key Files**: {Files currently in focus/being worked on}
#    - **TodoWrite State**: {Active todos with completion status}
#    - **Error Context**: {Recent failures, warnings, blocked operations}
#    - **Conversation Flow**: {Key decisions made, current problem focus}
#
#    ## Next Steps
#    - [ ] {Generated action items based on current state}
#    - [ ] {Continue from current progress}
#    - [ ] {Address any identified blockers}
#
#    ## Claude Code Next Steps
#    ### Immediate Actions
#    - [ ] `cd {full_directory_path}` - Restore exact working directory
#    - [ ] Verify worktree: `git worktree list` - Confirm worktree context
#    - [ ] Use Read tool on `{specific_files}` - Continue analysis of key files
#    - [ ] Run `{validation_commands}` - Validate current state
#    - [ ] {Specific tool sequences needed to resume work}
#
#    ### Worktree Restoration (if needed)
#    - [ ] `git worktree add {worktree_path} {branch}` - Recreate worktree if missing
#    - [ ] `cd {worktree_path}` - Navigate to correct worktree
#    - [ ] Verify branch: `git branch --show-current` - Confirm correct branch context
#
#    ### Conversation Continuation Prompts
#    - "Continue working on {specific_problem_context}"
#    - "Resume analysis of {specific_component_or_issue}"
#    - "The last step was {specific_action}, next I need to {specific_next_action}"
#    - "Help me {specific_continuation_request} based on the saved context"
#
#    ## Technical Details
#    ### Files Modified
#    {List of changed files with brief analysis}
#
#    ### Recent Commits
#    {Last 3-5 commits with messages}
#
#    ### Key Findings
#    {Important discoveries, solutions, workarounds}
#
#    ### Current Status
#    {Git status, any uncommitted changes, current directory context}
#
#    ---
#    *Session saved automatically on {timestamp} by Claude Code*
#    ```
#
# 5. CLAUDE CODE CONTEXT INTEGRATION:
#    - Capture current working directory using pwd command
#    - Analyze recent tool usage patterns and outcomes (Read, Edit, Bash, Grep, MCP)
#    - Extract active file contexts and work-in-progress states
#    - Record any TodoWrite states with completion tracking
#    - Capture recent error contexts, warnings, and blocked operations
#    - Generate conversation continuation prompts based on current work focus
#
# 6. CUSTOM CONTENT INTEGRATION:
#    - If CUSTOM_SUMMARY provided, incorporate into "Progress Made" section
#    - If SESSION_TYPE provided, use in overview, otherwise auto-detect from:
#      * Branch name patterns (feat/, fix/, chore/, docs/, test/)
#      * Commit message patterns
#      * Modified file types and contexts
#
# 7. NEXT STEPS GENERATION:
#    - Analyze current git status for uncommitted changes
#    - Check for TODO comments in recently modified files
#    - Generate contextual action items based on:
#      * Incomplete work (uncommitted changes)
#      * Testing needs (if test files modified)
#      * Documentation needs (if code without docs)
#      * Deployment needs (if infrastructure changes)
#    - Create Claude Code-specific immediate actions:
#      * Working directory restoration commands
#      * Specific tool sequences to resume work
#      * File examination recommendations
#      * Validation commands to run
#    - Generate conversation continuation prompts for seamless resumption
#
# 8. FINAL OUTPUT:
#    - Confirm successful note creation/update
#    - Display note title and location
#    - Show key Claude Code next steps extracted
#    - Provide quick summary of session progress
#    - Display conversation continuation prompts ready for use
#
# EXECUTION REQUIREMENTS:
# - Use structured bash commands and template-based generation for efficiency
# - Be thorough but concise - optimize for future session startup and token usage
# - Apply simple conditional logic for edge cases (no git repo, minimal changes, existing notes)
# - Use direct command sequences rather than AI analysis for routine operations
# - Ensure all markdown formatting is clean and readable
# ===================================================================================

echo "🚀 Claude will now perform autonomous session analysis and Obsidian note creation..."

# Session variables for Claude to use
export CUSTOM_SUMMARY="$CUSTOM_SUMMARY"
export SESSION_TYPE="$SESSION_TYPE"
export FORCE_UPDATE="$FORCE_UPDATE"
export OBSIDIAN_PATH="second_brain/Binbash/sessions"

# Extract current context for Claude analysis
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "no-git-repo")
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(date +"%Y-%m-%d %H:%M")

echo "📊 Session Context:"
echo "   Branch: $CURRENT_BRANCH"
echo "   Date: $CURRENT_DATE"
echo "   Custom Summary: ${CUSTOM_SUMMARY:-'Auto-generated'}"
echo "   Session Type: ${SESSION_TYPE:-'Auto-detected'}"
echo "   Update Mode: ${FORCE_UPDATE:-'false'}"

echo "✅ Ready for Claude autonomous execution with Obsidian MCP integration"