#!/usr/bin/env bash
# just-claude hook script
# Detects justfile and generates Claude Code skills

set -euo pipefail

# Use CLAUDE_PROJECT_DIR for absolute paths
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"
SKILLS_DIR="$PROJECT_ROOT/.claude/skills"

# Check if just command exists
if ! command -v just &> /dev/null; then
    echo "just-claude: just command not found, skipping skill generation" >&2
    exit 0
fi

# Check if justfile exists (just will auto-detect variants)
if ! just --dump --dump-format json &> /dev/null; then
    # No justfile or error - exit silently
    exit 0
fi

# Parse justfile and extract recipes
JUSTFILE_JSON=$(just --dump --dump-format json 2>/dev/null || echo '{}')

# Use Node.js to parse JSON and generate skills
node "$PROJECT_ROOT/node_modules/just-claude/lib/generator.js" "$PROJECT_ROOT" "$JUSTFILE_JSON"

exit 0
