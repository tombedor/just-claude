# just-claude

Automatically expose justfile recipes as Claude Code skills.

## Installation

```bash
npm install just-claude
```

That's it! The package will automatically:
- Detect your justfile
- Generate Claude Code skills for each recipe
- Configure Claude Code hooks

## Requirements

- Node.js 18+
- [just](https://github.com/casey/just) command runner
- [Claude Code](https://claude.com/claude-code)

## Quick Start

### 1. Create a Project with a Justfile

```bash
# Create a new project
mkdir my-project && cd my-project

# Create a simple justfile with a documented recipe
cat > justfile << 'EOF'
# Say hello (this comment becomes the recipe description)
hello name="world":
    echo "Hello, {{name}}!"
EOF
```

### 2. Install just-claude globally

```bash
npm install -g just-claude
```

This gives you the reusable `just-claude` CLI. Recommended default: global install keeps commands fast, works offline, and is the common pattern for CLIs.

### 3. Initialize the repo (hooks + skills)

```bash
# From inside the repo you want to wire up
just-claude init   # will prompt to add generated skills to .gitignore
```

This runs the same init logic as `npm install`, plus skill generation:
- Creates `.claude/hooks/detect-justfile.sh`
- Configures `.claude/settings.json` with a SessionStart hook
- Generates skills from your justfile
- Leaves no package.json or lockfile behind

### 4. See It In Action

```bash
# Check what was installed
just-claude status

# Output:
# just command: ✓ available
# justfile: ✓ found
# public recipes: 1
# generated skills: 1
# hook configured: ✓ yes

# See what skills were created
just-claude list

# Output:
# Generated skills:
#   - just-hello

# Check a generated skill
cat .claude/skills/just-hello/SKILL.md
```

### 5. Use with Claude Code

Now when you start Claude Code, it will automatically detect your justfile recipes. Try asking Claude to greet someone:

**You:** "Say hello to Redwood City"

**Claude:** *Sees the `just-hello` skill and runs `just hello "Redwood City"`*

That's it! Your justfile recipes are now Claude Code skills.

## How It Works

1. On `npm install`, just-claude:
   - Copies a SessionStart hook to `.claude/hooks/`
   - Configures `.claude/settings.json` with the hook
   - Backs up any existing settings

2. When Claude Code starts:
   - The hook detects your justfile
   - Parses recipes using `just --dump --dump-format json`
   - Generates skills for each public recipe
   - Skips private recipes (starting with `_`)

3. Claude can now:
   - Discover your just recipes as skills
   - Use them automatically when appropriate
   - Understand recipe parameters and documentation

## Features

### Automatic Skill Generation

Your justfile recipes automatically become Claude skills:

```just
# Build the project
build:
    cargo build --release

# Run tests
test:
    cargo test
```

Creates skills `just-build` and `just-test` with full documentation.

### Recipe Parameters

Recipes with parameters are fully supported:

```just
# Deploy to target environment
deploy target:
    ./deploy.sh {{target}}

# Start server on specified port
serve port="8080":
    cargo run -- --port {{port}}
```

Claude understands which parameters are required vs optional.

### Module Support

Submodules work seamlessly:

```just
# Main justfile
build:
    echo "main build"

mod backend
```

```just
# backend/justfile
deploy:
    echo "deploying backend"
```

Creates both `just-build` and `just-backend-deploy` skills.

### Private Recipes

Recipes starting with `_` are automatically excluded:

```just
# This becomes a skill
public-recipe:
    echo "visible"

# This is skipped
_private-helper:
    echo "internal only"
```

## CLI Commands

### Status

Check your installation and justfile status:

```bash
just-claude status
```

Output:
```
just-claude status

just command: ✓ available
justfile: ✓ found
public recipes: 8
generated skills: 8
hook configured: ✓ yes
```

### List

See all generated skills:

```bash
just-claude list
```

Output:
```
Generated skills:
  - just-build
  - just-test
  - just-deploy
  - just-serve
```

### Init (sync)

Install hooks (if needed) and regenerate skills from your justfile:

```bash
just-claude init            # prompts to gitignore generated skills
just-claude init -i         # force add .claude/skills/just-*/ to .gitignore
just-claude init --no-git-ignore  # skip gitignore changes
```

Run this after you add/remove recipes during a Claude Code session.

### Clean

Remove all generated skills:

```bash
just-claude clean
```

## Configuration

### Git Integration

Add to your `.gitignore`:

```gitignore
# Just-claude generated files
.claude/skills/just-*/
.claude/settings.json.backup
```

Do commit these files:
- `.claude/settings.json` - Hook configuration
- `.claude/hooks/detect-justfile.sh` - Hook script

### Existing Settings

If you already have `.claude/settings.json`, just-claude:
- Creates a backup (`.claude/settings.json.backup`)
- Merges the hook configuration
- Preserves your existing hooks and settings

## Examples

See [examples/example-justfile](examples/example-justfile) for a comprehensive example.

## Troubleshooting

### Skills not appearing

1. Check installation:
   ```bash
   just-claude status
   ```

2. Verify justfile syntax:
   ```bash
   just --dump --dump-format json
   ```

3. Manually sync:
   ```bash
   just-claude init
   ```

### Hook not running

Verify `.claude/settings.json` contains:
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

### Skills won't update

Clean and re-init:
```bash
just-claude clean
just-claude init
```

## Uninstall

```bash
npm uninstall just-claude
```

This automatically:
- Removes the hook script
- Cleans up generated skills
- Removes hook configuration from settings.json
- Restores backup if no other hooks remain

## Develop / Install from Source

```bash
# Clone and build locally
git clone https://github.com/yourusername/just-claude.git
cd just-claude
npm install
npm test

# Install the CLI globally from source
npm install -g .

# Wire up a project (from inside the target repo)
just-claude init
```

## Development

This project uses its own justfile for development tasks!

```bash
# Run tests
just test

# Run tests with detailed explanations
just test-full

# Run tests in watch mode
just test-watch

# Quick smoke test
just smoke-test

# Build package
just build

# Create local test environment
just test-local

# Show all commands
just help
```

The `just test-full` command runs tests and explains any failures:
- Missing dependencies → Run `just install`
- Syntax errors → Check error output
- Breaking changes → Review recent changes

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

MIT
