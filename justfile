# just-claude development justfile

# Run all tests
test:
    @echo "Running all tests..."
    npm test

# Run tests with detailed output
test-verbose:
    @echo "Running tests with verbose output..."
    npm test -- --reporter=tap

# Run tests in watch mode
test-watch:
    @echo "Running tests in watch mode (will auto-rerun on changes)..."
    npm run test:watch

# Install dependencies
install:
    @echo "Installing dependencies..."
    npm install

# Build package tarball
build:
    @echo "Building package..."
    npm pack
    @echo "✓ Package built: just-claude-0.1.0.tgz"

# Build and show contents
build-inspect:
    @echo "Building and inspecting package..."
    npm pack
    tar -tzf just-claude-0.1.0.tgz

# Clean build artifacts
clean:
    @echo "Cleaning build artifacts..."
    rm -f just-claude-*.tgz
    rm -rf node_modules
    @echo "✓ Cleaned"

# Run linting (placeholder for future)
lint:
    @echo "Linting code..."
    @echo "✓ No linter configured yet"

# Format code (placeholder for future)
fmt:
    @echo "Formatting code..."
    @echo "✓ No formatter configured yet"

# Create a local test environment
test-local:
    @echo "Creating local test environment..."
    rm -rf /tmp/just-claude-test
    mkdir -p /tmp/just-claude-test
    cd /tmp/just-claude-test && echo '# Build project\nbuild:\n    echo "building"\n\n# Run tests\ntest:\n    echo "testing"' > justfile
    cd /tmp/just-claude-test && echo '{"name":"test","version":"1.0.0"}' > package.json
    cd /tmp/just-claude-test && npm install {{justfile_directory()}}
    @echo "✓ Test environment created at /tmp/just-claude-test"
    @echo ""
    @echo "To test:"
    @echo "  cd /tmp/just-claude-test"
    @echo "  just-claude init"
    @echo "  just-claude status"
    @echo "  just-claude list"

# Run full test suite with explanations
test-full:
    #!/usr/bin/env bash
    set -e

    echo "=== Running just-claude test suite ==="
    echo ""

    echo "1. Running unit tests..."
    if npm test 2>&1 | tee /tmp/test-output.txt; then
        PASS=$(grep "# pass" /tmp/test-output.txt | awk '{print $3}')
        FAIL=$(grep "# fail" /tmp/test-output.txt | awk '{print $3}')
        echo "✓ Tests passed: $PASS passed, $FAIL failed"
    else
        echo "✗ Tests failed!"
        echo ""
        echo "Common causes of test failures:"
        echo "  - Missing dependencies: Run 'just install'"
        echo "  - Syntax errors in code: Check error output above"
        echo "  - Breaking changes: Review recent changes"
        exit 1
    fi

    echo ""
    echo "2. Building package..."
    if npm pack > /dev/null 2>&1; then
        SIZE=$(ls -lh just-claude-*.tgz | awk '{print $5}')
        echo "✓ Package built successfully ($SIZE)"
    else
        echo "✗ Package build failed!"
        echo "  Check package.json and file includes"
        exit 1
    fi

    echo ""
    echo "3. Testing local installation..."
    rm -rf /tmp/just-claude-quicktest
    mkdir -p /tmp/just-claude-quicktest
    cd /tmp/just-claude-quicktest
    echo 'test:\n    echo "test"' > justfile
    echo '{"name":"test","version":"1.0.0"}' > package.json

    if npm install {{justfile_directory()}}/just-claude-*.tgz > /dev/null 2>&1; then
        echo "✓ Installation works"
    else
        echo "✗ Installation failed!"
        echo "  Check postinstall script"
        exit 1
    fi

    cd {{justfile_directory()}}
    rm -rf /tmp/just-claude-quicktest

    echo ""
    echo "==================================="
    echo "✅ All tests passed!"
    echo "==================================="

# Quick smoke test
smoke-test:
    #!/usr/bin/env bash
    set -e

    echo "Running quick smoke test..."

    # Run unit tests
    npm test > /dev/null 2>&1 && echo "✓ Unit tests pass" || (echo "✗ Unit tests failed"; exit 1)

    # Build package
    npm pack > /dev/null 2>&1 && echo "✓ Package builds" || (echo "✗ Package build failed"; exit 1)

    # Test installation
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    echo 'test:\n    echo "test"' > justfile
    echo '{"name":"test","version":"1.0.0"}' > package.json
    npm install {{justfile_directory()}}/just-claude-*.tgz > /dev/null 2>&1 && echo "✓ Installation works" || (echo "✗ Installation failed"; exit 1)
    cd {{justfile_directory()}}
    rm -rf "$TMP_DIR"
    rm -f just-claude-*.tgz

    echo ""
    echo "✅ Smoke test passed!"

# Show package info
info:
    @echo "just-claude package information:"
    @echo ""
    @echo "Version: $(cat package.json | grep version | awk -F'"' '{print $4}')"
    @echo "Main: $(cat package.json | grep '\"main\"' | awk -F'"' '{print $4}')"
    @echo "Bin: $(cat package.json | grep '\"just-claude\"' | awk -F'"' '{print $4}')"
    @echo ""
    @echo "Files:"
    @find bin lib scripts templates -type f | head -20
    @echo ""
    @echo "Documentation:"
    @ls -lh README.md PRD.md ROADMAP.md CONTRIBUTING.md | awk '{print "  " $9 " (" $5 ")"}'

# Publish a new version (patch, minor, or major)
publish version:
    #!/usr/bin/env bash
    set -e

    # Validate version argument
    if [[ "{{version}}" != "patch" && "{{version}}" != "minor" && "{{version}}" != "major" ]]; then
        echo "Error: version must be 'patch', 'minor', or 'major'"
        exit 1
    fi

    echo "=== Publishing new {{version}} version ==="
    echo ""

    # Ensure working directory is clean
    if [[ -n $(git status -s) ]]; then
        echo "Error: Working directory is not clean. Commit or stash changes first."
        git status -s
        exit 1
    fi

    # Ensure we're on main branch
    BRANCH=$(git branch --show-current)
    if [[ "$BRANCH" != "main" ]]; then
        echo "Warning: You're on branch '$BRANCH', not 'main'"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Run tests
    echo "1. Running tests..."
    npm test || (echo "✗ Tests failed! Fix tests before publishing."; exit 1)
    echo "✓ Tests passed"
    echo ""

    # Bump version and create git tag
    echo "2. Bumping {{version}} version..."
    NEW_VERSION=$(npm version {{version}} --no-git-tag-version)
    echo "✓ Version bumped to $NEW_VERSION"
    echo ""

    # Commit version bump
    echo "3. Committing version bump..."
    git add package.json
    git commit -m "Bump version to $NEW_VERSION"
    echo "✓ Committed"
    echo ""

    # Create and push tag
    echo "4. Creating and pushing tag..."
    git tag "$NEW_VERSION"
    git push origin "$BRANCH"
    git push origin "$NEW_VERSION"
    echo "✓ Pushed $NEW_VERSION to GitHub"
    echo ""

    echo "==================================="
    echo "✅ Version $NEW_VERSION published!"
    echo "==================================="
    echo ""
    echo "GitHub Actions will now:"
    echo "  1. Run tests"
    echo "  2. Publish to npm registry"
    echo ""
    echo "Monitor progress at:"
    echo "  https://github.com/tombedor/just-claude/actions"

# Show help
help:
    @echo "just-claude development commands:"
    @echo ""
    @echo "  just test           - Run all tests"
    @echo "  just test-full      - Run tests with explanations"
    @echo "  just test-watch     - Run tests in watch mode"
    @echo "  just smoke-test     - Quick validation"
    @echo ""
    @echo "  just build          - Build package tarball"
    @echo "  just test-local     - Create local test environment"
    @echo ""
    @echo "  just publish patch  - Publish a patch version (0.1.0 -> 0.1.1)"
    @echo "  just publish minor  - Publish a minor version (0.1.0 -> 0.2.0)"
    @echo "  just publish major  - Publish a major version (0.1.0 -> 1.0.0)"
    @echo ""
    @echo "  just install        - Install dependencies"
    @echo "  just clean          - Clean build artifacts"
    @echo ""
    @echo "  just info           - Show package information"
    @echo "  just help           - Show this help"
