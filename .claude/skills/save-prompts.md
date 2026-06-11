---
description: "Save conversation prompts to Obsidian with original and polished versions"
argument-hint: "[path] [filename] [title]"
allowed-tools: ["Write", "Bash"]
---

# Save Conversation Prompts to Obsidian

Create a structured Obsidian note template for saving conversation prompts with both original and polished versions.

**Arguments:**
- `path` - Relative path to default Obsidian MCP vault folder / (default: "AI"). Can be "Folder" or "Folder/Subfolder"
- `filename` - Base filename without .md extension (default: auto-generated with timestamp)
- `title` - Note title (default: auto-generated with current date/time)

**Examples:**
- `/save-prompts` - Uses defaults (AI folder, timestamped filename)
- `/save-prompts "Custom nginx-proxy"` - Uses "Custom nginx-proxy" as path
- `/save-prompts "Projects/Infrastructure" "nginx-implementation" "Nginx Working Session"` - Full specification

I'll create a comprehensive Obsidian note template with the following sections:

1. **Session Overview** - Summary and key outcomes
2. **Original Prompts** - Exact user prompts as written
3. **Polished Prompts** - Refined, reusable template versions
4. **Implementation Notes** - Decisions, technical details, lessons learned
5. **Artifacts & Results** - Files created, commands run, validation results
6. **Next Steps** - Immediate actions and future improvements
7. **Related Resources** - Links and references

The template includes:
- Structured sections with clear formatting
- Placeholder variables for reusability
- Usage guide for filling the template
- Automatic timestamping
- Rich markdown formatting with emojis and status indicators

**Usage Pattern:**
1. Run the command with desired path/filename
2. Open the created note in your editor
3. Fill in the original prompts exactly as written
4. Create polished, reusable versions with variables
5. Document implementation details and outcomes
6. Plan next steps and link related resources

This helps capture and structure conversation knowledge for future reference and reuse.