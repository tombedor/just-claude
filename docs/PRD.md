# Just-Claude: Justfile Integration for Claude Code

This project is an extension to Claude Code that automatically exposes justfile recipes as Claude Code skills.

## Overview

Upon startup, detect the presence of a justfile in the repo and dynamically create Claude Code skills for each recipe.

## Technical Decisions

### 1. Integration Approach
- **Implementation**: Claude Code SessionStart hook
- **Location**: `.claude/hooks/` directory with hook configuration in `.claude/settings.json`

### 2. Change Detection
- **Strategy**: SessionStart hook only (simple to start)
- **Behavior**: Recipes are detected when Claude Code starts/resumes
- **Future**: Could add PostToolUse hook for detecting changes during session

### 3. Recipe Handling

#### Included Recipes
- All public recipes (not starting with `_`)
- Recipes from root justfile AND declared modules (via `mod` statements)
- Recipes with required parameters
- Recipes with optional parameters

#### Excluded Recipes
- Private recipes (starting with `_`)

#### Parameters
- Expose all recipes regardless of parameters
- Document required/optional parameters in skill description
- Claude will prompt user for required parameters when needed

### 4. Module Support
- Parse root justfile for `mod` declarations
- Include recipes from submodules
- Use `just --dump --dump-format json` which provides full module tree
- Recipe namepath (e.g., `subdir::deploy`) used for invocation

### 5. Skill Naming and Documentation

#### Naming Convention
- Prefix all skills with `just-` to distinguish from other skills
- Root recipes: `just-<recipe-name>` (e.g., `just-build`)
- Module recipes: `just-<namepath>` (e.g., `just-subdir::deploy`)

#### Directory Structure
- Root recipes: `.claude/skills/just-<recipe-name>/SKILL.md`
- Module recipes: `.claude/skills/just-<module-name>/<recipe-name>/SKILL.md`
  - Example: `.claude/skills/just-subdir/deploy/SKILL.md`
  - Mirrors just's `::` namepath with nested directories

#### Recipe Name Safety
- Just enforces alphanumeric, dash, and underscore characters only
- No sanitization needed (just rejects unsafe characters)
- Directory names are guaranteed filesystem-safe

#### Documentation
- Use recipe doc comments from justfile as skill descriptions (auto-generated)
- Skill quality reflects justfile documentation quality (no enhancement)
- Document parameters in skill description (required vs optional)
- Include usage examples in skill prompt

### 6. Error Handling
- Warn in Claude console if justfile is malformed
- Warn if `just` command is not installed
- Gracefully handle missing optional modules
- Don't block Claude Code startup on errors

### 7. Skill Lifecycle
- Create skills on SessionStart if justfile exists
- Remove skills if justfile is deleted (detected on next session start)
- Don't affect any other Claude Code skills

## Package Structure

```
just-claude/
├── package.json
├── bin/
│   └── cli.js              # just-claude CLI commands
├── scripts/
│   ├── postinstall.js      # Runs after npm install
│   └── preuninstall.js     # Runs before npm uninstall
├── templates/
│   └── detect-justfile.sh  # Hook script template
└── lib/
    └── generator.js        # Shared skill generation logic
```

**Package name**: `just-claude` (available on npm)

## Installation & Configuration

### Installation
**Recommended: global install + per-repo init**
```bash
npm install -g just-claude
# then inside each repo
just-claude init
```

**What init does:**
- Copies `templates/detect-justfile.sh` to `.claude/hooks/detect-justfile.sh`
- Creates/updates `.claude/settings.json` to register the SessionStart hook
- Backs up existing `.claude/settings.json` if present (to `.claude/settings.json.backup`)
- Merges hook configuration into existing settings (doesn't overwrite)
- Generates skills from the justfile

**Package scope:** Per-project installation (not global)

### Uninstallation
**Single command removal:**
```bash
npm uninstall just-claude
```

**What it does:**
1. Preuninstall script automatically:
   - Removes hook configuration from `.claude/settings.json`
   - Removes `.claude/hooks/detect-justfile.sh`
   - Cleans up generated skill directories (`.claude/skills/just-*`)
   - Restores `.claude/settings.json.backup` if hooks array becomes empty after removal

### Configuration Merging Strategy

**Existing settings.json handling:**
- If `.claude/settings.json` doesn't exist: Create new with hook configuration
- If exists without hooks array: Add hooks array with SessionStart hook
- If exists with hooks array: Append SessionStart hook to existing hooks
- Never remove or modify other hooks/settings

**Example merged configuration:**
```json
{
  "hooks": [
    {
      "type": "SessionStart",
      "matchers": ["*"],
      "hooks": [
        {
          "type": "command",
          "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/detect-justfile.sh"
        }
      ]
    }
  ]
}
```

**Hook path**: Uses absolute path with `$CLAUDE_PROJECT_DIR` environment variable for reliability

## Requirements

### System Requirements
- **Node.js**: 18+ (current LTS)
- **Just**: Any version with JSON dump support (`--dump --dump-format json`)
- **Claude Code**: Version supporting hooks and skills
- **OS**: Any POSIX-compliant system (macOS, Linux, WSL)
- **Shell**: bash or compatible

### Feature Detection Strategy
Use feature detection instead of OS detection:
- Check if `just` command exists with `command -v just`
- Use `just --dump` to auto-detect justfile variants (justfile, Justfile, .justfile)
- Exit gracefully if dependencies missing (don't block Claude Code startup)

## Generated Skill Format

Each recipe generates a skill with this structure:

```yaml
---
name: just-build
description: [Auto-generated from recipe doc comment or recipe name]
---

# Justfile Recipe: build

[Recipe doc comment from justfile, if present]

## Usage
just build

## Parameters
None
```

For recipes with parameters:

```yaml
---
name: just-deploy
description: [Auto-generated from recipe doc comment or recipe name]
---

# Justfile Recipe: deploy

[Recipe doc comment from justfile, if present]

## Usage
just deploy <target>

## Parameters
- **target** (required): Deployment target
- **port** (optional, default: "8080"): Server port
```

### Skill Description Generation
- Auto-generated from recipe `doc` field in JSON output
- If no doc comment: Use recipe name as description
- Keep descriptions concise for skill frontmatter

### Generated File Marker
Each generated `SKILL.md` includes HTML comment:
```html
<!-- Generated by just-claude - Do not edit manually -->
```

This marker allows:
- Safe regeneration (overwrite generated skills)
- Conflict detection (skip manually created skills with same name)

## Edge Cases & Error Handling

### No Public Recipes
- Justfile exists but only contains private recipes (starting with `_`)
- **Action**: Don't create `.claude/skills/` directory, log info message

### Just Not Installed
- Justfile exists but `just` command not found
- **Action**: Log warning to stderr, exit gracefully (exit 0)

### Justfile Variants
- Support all variants: `justfile`, `Justfile`, `.justfile`
- **Implementation**: Use `just --dump` which auto-detects

### Skill Name Conflicts
- Skill directory `just-build` already exists
- **Action**: Check for `<!-- Generated by just-claude -->` marker
  - If present: Overwrite (regenerate)
  - If absent: Skip, log warning about manual skill

### Large Justfiles
- 100+ recipes in a single justfile
- **Action**: No limit, generate all skills (rare case)

### Malformed Justfile
- Justfile has syntax errors
- **Action**: `just --dump` fails, log error, exit gracefully

## Version Control & Git

### Gitignore Recommendations
Package provides `.gitignore` template:
```gitignore
# Just-claude generated files
.claude/skills/just-*/
.claude/settings.json.backup
```

### Rationale
- **Option C (Hybrid)**: Don't commit generated skills
- ✅ Clean diffs, no merge conflicts
- ✅ Skills regenerate on SessionStart hook
- ✅ Each developer runs `npm install` once
- ❌ Requires npm install after clone

### Files in Repository
- **Commit**: `.claude/settings.json` (hook configuration)
- **Commit**: `.claude/hooks/detect-justfile.sh` (hook script)
- **Gitignore**: `.claude/skills/just-*/` (generated skills)
- **Gitignore**: `.claude/settings.json.backup` (backup files)

## Manual CLI Commands

Package provides CLI for manual operations:

### Init / Sync Skills
```bash
just-claude init
```
Install hooks (if needed) and refresh skills from current justfile (run after justfile edits).

### List Generated Skills
```bash
just-claude list
```
Display all just-claude generated skills with recipe info.

### Clean Generated Skills
```bash
just-claude clean
```
Remove all generated skill directories (`.claude/skills/just-*`).

### Status Check
```bash
just-claude status
```
Show:
- Whether justfile exists
- Number of public recipes found
- Number of generated skills
- `just` command availability

## Testing Strategy

### Unit Tests
- JSON parsing from `just --dump --dump-format json`
- Parameter extraction (required vs optional)
- Private recipe filtering
- Module/submodule handling
- Skill name generation

### Integration Tests
- Test with various justfile configurations:
  - Simple recipes (no params)
  - Recipes with required params
  - Recipes with optional params
  - Recipes with modules
  - Private recipes
  - Empty justfile
  - No justfile
- Hook script execution
- Settings.json merging logic

### NPM Lifecycle Tests
- Postinstall script creates hooks and settings
- Preuninstall script cleans up
- Backup/restore of existing settings.json

### Test Framework
- **Unit tests**: Jest or Node.js built-in test runner
- **Integration tests**: Temporary directories with real justfiles
- **Shell tests**: bats (Bash Automated Testing System) for hook script

## Hook Execution Context

### Environment Variables
- **`CLAUDE_PROJECT_DIR`**: Absolute path to project root (use for all paths)
- **`CLAUDE_CODE_REMOTE`**: Set to "true" in web environments
- **`INIT_CWD`**: NPM variable for install location (postinstall only)

### Hook Input/Output Protocol

**SessionStart stdin** (JSON):
```json
{
  "session_id": "abc123",
  "source": "startup|resume|clear|compact",
  "hook_event_name": "SessionStart"
}
```

**Hook output**:
- **stdout + exit 0**: Message added as context to Claude
- **stderr + exit 1**: Non-blocking warning (shown in verbose mode)
- **stderr + exit 2**: Blocking error (halts session, shown to user)

**Example hook logging**:
```bash
#!/bin/bash
# Success with context
echo "Generated 5 just-claude skills from justfile"
exit 0

# Warning (just not installed)
echo "Warning: just command not found, skipping skill generation" >&2
exit 0  # Non-blocking

# Error (malformed justfile)
echo "Error: Justfile syntax error - just --dump failed" >&2
exit 0  # Non-blocking (don't halt Claude Code)
```

### Working Directory
- Hooks execute from current directory (typically project root)
- Always use `$CLAUDE_PROJECT_DIR` for absolute path references
- Never rely on relative paths

## Implementation Notes

- Use `just --dump --dump-format json` to parse recipes and modules
- Create skill directories in `.claude/skills/just-<recipe-name>/SKILL.md`
- Module recipes use nested directories: `.claude/skills/just-<module>/<recipe>/SKILL.md`
- Each skill has a `SKILL.md` file with YAML frontmatter
- Hook script handles skill creation/deletion
- NPM postinstall/preuninstall scripts handle setup/teardown
- Feature detection over OS detection for maximum portability
- Hook uses absolute paths via `$CLAUDE_PROJECT_DIR`
- All recipe names are filesystem-safe (just enforces this)
