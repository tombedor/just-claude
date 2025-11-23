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

1. **Install just-claude in your project:**
   ```bash
   npm install just-claude
   ```

2. **Start Claude Code:**
   Your justfile recipes are now available as skills!

3. **Verify installation:**
   ```bash
   npx just-claude status
   ```

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
npx just-claude status
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
npx just-claude list
```

Output:
```
Generated skills:
  - just-build
  - just-test
  - just-deploy
  - just-serve
```

### Regenerate

Manually refresh skills after editing justfile:

```bash
npx just-claude regenerate
```

Useful when you add/remove recipes during a Claude Code session.

### Clean

Remove all generated skills:

```bash
npx just-claude clean
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
   npx just-claude status
   ```

2. Verify justfile syntax:
   ```bash
   just --dump --dump-format json
   ```

3. Manually regenerate:
   ```bash
   npx just-claude regenerate
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

### Skills won't regenerate

Clean and regenerate:
```bash
npx just-claude clean
npx just-claude regenerate
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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

MIT
