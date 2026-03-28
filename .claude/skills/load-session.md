---
description: "Intelligently load and resume from saved session notes with contextual workspace restoration"
allowed-tools: ["Bash", "mcp__obsidian__search_notes", "mcp__obsidian__read_notes"]
---

# Load Session Progress

Intelligent session discovery and restoration system that complements `/save-session`. Provides seamless workflow continuation through smart session loading, contextual analysis, and interactive workspace restoration.

**Key Features:**
- 🔍 **Smart Auto-Load**: Automatically loads most recent session for current git branch
- 📋 **Interactive List**: Latest 5 sessions with rich metadata and selection interface
- 🎯 **Contextual Analysis**: AI-powered session summaries and state-aware diffs
- ✅ **Actionable Tasks**: Interactive next steps with real-time Obsidian updates
- 🔎 **Content Search**: Find sessions by keywords, branches, or date ranges
- 📊 **Progress Context**: Compare current state with saved session context

Usage: `/load-session [mode] [args] [--options]`

**Primary Modes:**
- `/load-session` - Auto-load most recent session for current branch
- `/load-session list` - Show interactive list of latest 5 sessions
- `/load-session 3` - Load session #3 from list
- `/load-session search "keyword"` - Search sessions by content
- `/load-session 2024-01-15` - Load session by date
- `/load-session --branch feat/auth` - Load latest from specific branch

# Advanced argument parsing and mode detection
MODE="${1:-auto}"
SEARCH_TERM="${2:-}"
TARGET_BRANCH="${3:-}"

# Parse optional arguments and detect mode
case "$MODE" in
  [0-9]*)
    # Numeric argument - direct session load
    SESSION_NUMBER="$MODE"
    MODE="direct"
    ;;
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
    # Date pattern - date-based load
    SESSION_DATE="$MODE"
    MODE="date"
    ;;
  list)
    MODE="list"
    ;;
  search)
    MODE="search"
    if [[ -z "$SEARCH_TERM" ]]; then
      echo "❌ Usage: /load-session search \"keyword\""
      exit 1
    fi
    ;;
  auto)
    MODE="auto"
    ;;
  --branch)
    MODE="branch"
    TARGET_BRANCH="$SEARCH_TERM"
    if [[ -z "$TARGET_BRANCH" ]]; then
      echo "❌ Usage: /load-session --branch branch-name"
      exit 1
    fi
    ;;
  *)
    # Default to search if argument provided
    if [[ -n "$MODE" ]]; then
      SEARCH_TERM="$MODE"
      MODE="search"
    else
      MODE="auto"
    fi
    ;;
esac

echo "🔍 Loading session using mode: $MODE"

# ===================================================================================
# CLAUDE: MANDATORY - Comprehensive Session Loading and Restoration
# ===================================================================================
#
# You MUST perform comprehensive session analysis and loading based on the detected mode:
#
# 1. SESSION DISCOVERY AND SEARCH:
#    - Use mcp__obsidian__search_notes to find sessions in "second_brain/Binbash/sessions"
#    - Search pattern should match worktree-aware session naming: "{YYYY-MM-DD} - {branch} - {worktree-context} - Session Notes"
#    - Extract current worktree context using git worktree list and pwd for filtering
#    - Handle multiple results and rank by recency/relevance and worktree context match
#    - Consider both timestamped sessions (collision-resolved) and standard naming
#
# 2. MODE-SPECIFIC BEHAVIOR:
#
#    **AUTO MODE** (default):
#    - Extract current git branch and worktree context using bash
#    - Search for most recent session matching current branch + worktree context
#    - If no exact worktree match, search for branch match with worktree warning
#    - If no branch match, load most recent session overall with context mismatch warning
#    - Provide smart context switching recommendations and worktree guidance
#
#    **LIST MODE**:
#    - Find latest 5 session notes, sorted by date (newest first)
#    - Extract metadata from each note: date, branch, worktree context, type, progress indicators
#    - Group sessions by worktree context and highlight current worktree matches
#    - Display formatted list with numbered selection:
#      ```
#      📋 Latest Sessions:
#      [1] 2024-01-15 - fix/opentofu-compatibility - kms-worktree
#          🐛 Bug Fix | 📁 /project/worktrees/kms | ⏱️ 2h 30m | 🔄 4 commits | ❗ 2 blockers
#          📝 Next: Run final tests, update documentation
#
#      [2] 2024-01-14 - feat/bedrock-integration - main-repo
#          🚀 Feature | 📁 /project/main | ⏱️ 1h 45m | 🔄 2 commits | ✅ Complete
#          📝 Next: Code review, deployment prep
#      ```
#    - Mark current worktree matches with ✅ indicator
#    - Wait for user selection or auto-select if running programmatically
#
#    **DIRECT MODE** (numeric argument):
#    - Use SESSION_NUMBER to load specific session from latest list
#    - Skip list display, go directly to session restoration
#
#    **SEARCH MODE**:
#    - Use mcp__obsidian__search_notes with SEARCH_TERM across session content
#    - Include worktree paths and directory contexts in searchable content
#    - Rank results by relevance, recency, and worktree context match
#    - Display matching sessions with context snippets and worktree information
#    - Allow selection from search results with worktree context indicators
#
#    **DATE MODE** (YYYY-MM-DD pattern):
#    - Search for session with exact SESSION_DATE
#    - Handle multiple sessions on same date (morning/afternoon)
#    - Load most recent if multiple matches
#
#    **BRANCH MODE** (--branch flag):
#    - Search for latest session matching TARGET_BRANCH
#    - Consider worktree context when multiple same-branch sessions exist
#    - Display branch-specific session history with worktree differentiation
#    - Recommend if current branch/worktree differs from session context
#    - Provide worktree disambiguation for same branch in different worktrees
#
# 3. SESSION ANALYSIS AND RESTORATION:
#    For selected session, use mcp__obsidian__read_notes and perform:
#
#    **Context Extraction**:
#    - Parse session metadata (date, branch, type, duration)
#    - Extract original objectives and context
#    - Identify progress made and accomplishments
#    - List current issues and blockers
#    - Extract Claude Code context (tool usage, workspace, active files)
#    - Parse conversation continuation prompts from saved session
#
#    **State-Aware Analysis**:
#    - Compare session's git context with current state using bash
#    - Extract and compare worktree context from session vs current worktree list
#    - Identify files mentioned in session that have changed since save
#    - Generate diff summary of changes since session
#    - Highlight potential conflicts or relevant updates
#    - Compare saved working directory with current directory (with worktree context)
#    - Analyze file accessibility and modification status since session
#    - Detect worktree mismatches and provide restoration guidance
#    - Check if saved worktree still exists or has been pruned
#
#    **Next Steps Processing**:
#    - Extract markdown checkboxes (- [ ]) from session notes
#    - Parse Claude Code-specific next steps and immediate actions
#    - Present as interactive task list with workspace restoration commands
#    - Identify urgent, blocked, or ready-to-execute items
#    - Extract conversation continuation prompts for immediate use
#    - Provide time estimates where available
#
# 4. INTELLIGENT SUMMARY GENERATION:
#    Use structured analysis and template-based generation to create:
#    - **Quick Context Summary**: 2-3 sentence overview of session goals and status
#    - **Progress Recap**: What was accomplished and current state
#    - **Immediate Actions**: Top 3 next steps to resume work efficiently
#    - **Context Switching Notes**: Warnings if branch/environment/worktree differs
#    - **Worktree Validation**: Status of saved worktree vs current context
#    - **Directory Mismatch Warnings**: Clear guidance when directory context differs
#    - **Workspace Restoration Summary**: Commands needed to restore Claude Code working state
#    - **Conversation Restart Strategy**: Best prompts to continue seamlessly
#
# 5. WORKSPACE RESTORATION OUTPUT:
#    Present comprehensive session restoration information:
#
#    ```markdown
#    # 📖 Session Loaded: {Title}
#
#    ## 🎯 Quick Context Summary
#    {AI-generated 2-3 sentence overview}
#
#    ## 📊 Session Overview
#    - **Date**: {Original date and time}
#    - **Branch**: {Git branch} {current branch warning if different}
#    - **Type**: {Session type with emoji}
#    - **Duration**: {Estimated time spent}
#    - **Status**: {Complete/In Progress/Blocked}
#
#    ## 🔄 Workspace Restoration
#    ### Worktree & Directory Context
#    - **Saved Worktree**: {original worktree path or 'main repository'}
#    - **Saved Directory**: {full directory path from session}
#    - **Current Worktree**: {current worktree context}
#    - **Current Directory**: {current pwd}
#    - **⚠️ Context Mismatch**: {warning if worktree/directory differs}
#
#    ### Quick Setup Commands
#    ```bash
#    # Directory restoration
#    cd {saved_full_directory_path}
#
#    # Worktree verification/restoration (if needed)
#    git worktree list  # Check existing worktrees
#    # If worktree missing: git worktree add {worktree_path} {branch}
#
#    # Validate context
#    git branch --show-current  # Confirm branch
#    pwd  # Verify directory
#    ```
#
#    ### Recommended Next Actions
#    1. {Specific tool to run first with file paths}
#    2. {Files to examine with reasoning}
#    3. {Commands to validate current state}
#    4. Verify worktree context matches session expectations
#
#    ## 🔄 Progress Since Session
#    {State-aware diff summary of changes}
#
#    ## ✅ Next Steps (Interactive)
#    - [ ] {Action item 1 - ready to execute}
#    - [ ] {Action item 2 - blocked by X}
#    - [ ] {Action item 3 - needs Y}
#
#    ## 💬 Conversation Restart Prompts
#    **Ready-to-use prompts for seamless continuation:**
#    - "Continue working on {specific_problem_context}"
#    - "Resume analysis of {specific_component_or_issue}"
#    - "The last step was {specific_action}, next I need to {specific_next_action}"
#
#    ## 📁 Key Files from Session
#    {List of important files mentioned with current status and accessibility}
#
#    ## 🔍 Context & Background
#    {Original objectives and relevant background}
#    ```
#
# 6. ADVANCED FEATURES:
#
#    **Git Integration**:
#    - Offer to checkout session branch if different from current
#    - Show commit history since session for context
#    - Identify if session branch has been merged/deleted
#
#    **File Context**:
#    - List files that were actively modified in session
#    - Check if files still exist and show modification status
#    - Suggest reopening relevant files with specific Read commands
#    - Provide file accessibility warnings
#
#    **Claude Code Workspace Integration**:
#    - Compare saved working directory with current directory (worktree-aware)
#    - Provide specific cd commands and worktree setup for workspace restoration
#    - Extract tool usage patterns from saved session with directory context
#    - Generate ready-to-execute command sequences with worktree validation
#    - Handle worktree switching and directory navigation commands
#    - Provide worktree recreation commands if worktree was pruned
#
#    **Dependency Analysis**:
#    - Check if dependencies (package.json, etc.) changed since session
#    - Alert about potential environment drift
#
# 7. ERROR HANDLING:
#    - Handle case where no sessions found (new user)
#    - Gracefully handle malformed session notes
#    - Provide helpful suggestions when sessions not found for branch/date/worktree
#    - Handle Obsidian MCP connection issues
#    - Handle cases where saved worktree has been pruned or deleted
#    - Provide guidance when worktree context cannot be determined
#    - Handle permission issues with different worktree paths
#    - Gracefully handle non-git directories or corrupted git worktree state
#
# EXECUTION REQUIREMENTS:
# - Use structured logic and template-based generation for efficient processing
# - Apply simple conditional logic for complex analysis and decision making
# - Provide rich, actionable output optimized for immediate productivity and token efficiency
# - Handle all edge cases gracefully with helpful error messages
# - Use direct command sequences rather than AI analysis for routine operations
# - Ensure output is well-formatted and easy to scan quickly
# ===================================================================================

echo "🚀 Claude will now perform comprehensive session discovery and restoration..."

# Session variables for Claude analysis
export LOAD_MODE="$MODE"
export SESSION_NUMBER="${SESSION_NUMBER:-}"
export SESSION_DATE="${SESSION_DATE:-}"
export SEARCH_TERM="${SEARCH_TERM:-}"
export TARGET_BRANCH="${TARGET_BRANCH:-}"
export OBSIDIAN_PATH="second_brain/Binbash/sessions"
export CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "no-git-repo")
export CURRENT_DATE=$(date +"%Y-%m-%d")

echo "📊 Load Configuration:"
echo "   Mode: $LOAD_MODE"
echo "   Current Branch: $CURRENT_BRANCH"
echo "   Search Term: ${SEARCH_TERM:-'N/A'}"
echo "   Target Branch: ${TARGET_BRANCH:-'N/A'}"
echo "   Session Number: ${SESSION_NUMBER:-'N/A'}"
echo "   Session Date: ${SESSION_DATE:-'N/A'}"

echo "✅ Ready for Claude autonomous session loading with Obsidian MCP integration"