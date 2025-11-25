#!/usr/bin/env bash
# just-claude hook script
# Detects justfile and generates Claude Code skills

set -euo pipefail

# Use CLAUDE_PROJECT_DIR for absolute paths
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"

# Check if just-claude command exists
if ! command -v just-claude &> /dev/null; then
    # just-claude not installed - exit silently
    exit 0
fi

# Change to project directory and run just-claude generate
cd "$PROJECT_ROOT"
just-claude generate

exit 0
