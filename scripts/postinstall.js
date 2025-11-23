#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Get the project root directory where npm install was run
 */
function getProjectRoot() {
  // INIT_CWD is set by npm to the directory where npm was invoked
  return process.env.INIT_CWD || process.cwd();
}

/**
 * Copy hook script from package to project
 */
function installHookScript(projectRoot) {
  const packageDir = path.join(__dirname, '..');
  const hookSource = path.join(packageDir, 'templates', 'detect-justfile.sh');
  const hooksDir = path.join(projectRoot, '.claude', 'hooks');
  const hookDest = path.join(hooksDir, 'detect-justfile.sh');

  // Create .claude/hooks directory
  fs.mkdirSync(hooksDir, { recursive: true });

  // Copy hook script
  fs.copyFileSync(hookSource, hookDest);

  // Make executable
  fs.chmodSync(hookDest, 0o755);

  console.log('just-claude: Installed hook script to .claude/hooks/detect-justfile.sh');
}

/**
 * Configure settings.json with SessionStart hook
 */
function configureSettings(projectRoot) {
  const claudeDir = path.join(projectRoot, '.claude');
  const settingsFile = path.join(claudeDir, 'settings.json');
  const backupFile = path.join(claudeDir, 'settings.json.backup');

  // Ensure .claude directory exists
  fs.mkdirSync(claudeDir, { recursive: true });

  let settings = { hooks: [] };

  // Load existing settings if present
  if (fs.existsSync(settingsFile)) {
    try {
      const content = fs.readFileSync(settingsFile, 'utf-8');
      settings = JSON.parse(content);

      // Backup existing settings
      fs.writeFileSync(backupFile, content, 'utf-8');
      console.log('just-claude: Backed up existing settings.json');
    } catch (error) {
      console.error('just-claude: Warning - Could not parse existing settings.json:', error.message);
      settings = { hooks: [] };
    }
  }

  // Ensure hooks array exists
  if (!Array.isArray(settings.hooks)) {
    settings.hooks = [];
  }

  // Check if our hook is already configured
  const hookExists = settings.hooks.some(hook =>
    hook.type === 'SessionStart' &&
    hook.hooks &&
    hook.hooks.some(h => h.command && h.command.includes('detect-justfile.sh'))
  );

  if (hookExists) {
    console.log('just-claude: Hook already configured in settings.json');
    return;
  }

  // Add SessionStart hook
  const sessionStartHook = {
    type: 'SessionStart',
    matchers: ['*'],
    hooks: [
      {
        type: 'command',
        command: '$CLAUDE_PROJECT_DIR/.claude/hooks/detect-justfile.sh'
      }
    ]
  };

  settings.hooks.push(sessionStartHook);

  // Write updated settings
  fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2) + '\n', 'utf-8');
  console.log('just-claude: Configured SessionStart hook in settings.json');
}

/**
 * Main installation function
 */
function install() {
  try {
    const projectRoot = getProjectRoot();

    console.log('just-claude: Installing...');
    console.log(`just-claude: Project root: ${projectRoot}`);

    installHookScript(projectRoot);
    configureSettings(projectRoot);

    console.log('just-claude: Installation complete!');
    console.log('just-claude: Skills will be generated when Claude Code starts');
  } catch (error) {
    console.error('just-claude: Installation error:', error.message);
    console.error('just-claude: You may need to configure manually');
    process.exit(0); // Don't fail npm install
  }
}

// Run installation
install();
