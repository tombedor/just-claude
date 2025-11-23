# Contributing to just-claude

Thank you for your interest in contributing to just-claude!

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/just-claude.git
cd just-claude
```

2. Install dependencies:
```bash
npm install
```

3. Run tests:
```bash
npm test
```

## Project Structure

```
just-claude/
├── bin/cli.js              # CLI commands (status, list, etc.)
├── lib/generator.js        # Core skill generation logic
├── scripts/
│   ├── postinstall.js      # NPM install hook
│   └── preuninstall.js     # NPM uninstall hook
├── templates/
│   └── detect-justfile.sh  # SessionStart hook script
└── test/                   # Test files
```

## Making Changes

1. Create a new branch for your feature/fix
2. Make your changes
3. Add tests for new functionality
4. Ensure all tests pass: `npm test`
5. Submit a pull request

## Testing

### Unit Tests
```bash
npm test
```

### Manual Testing
```bash
# Create a test project
mkdir test-project && cd test-project
echo 'build:\n    echo "test"' > justfile

# Install from local development
npm install /path/to/just-claude

# Test CLI commands
npx just-claude status
npx just-claude list
npx just-claude regenerate
```

## Code Style

- Use clear, descriptive variable names
- Add comments for complex logic
- Follow existing code patterns
- Keep functions focused and modular

## Commit Messages

- Use clear, descriptive commit messages
- Start with a verb (Add, Fix, Update, etc.)
- Reference issues when applicable

## Reporting Issues

When reporting issues, please include:
- Your OS and Node.js version
- Steps to reproduce
- Expected vs actual behavior
- Error messages or logs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
