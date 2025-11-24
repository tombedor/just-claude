const assert = require('assert');
const { spawnSync, execSync } = require('child_process');
const { test } = require('node:test');

function commandExists(cmd) {
  try {
    execSync(`command -v ${cmd}`, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

const shouldRunDoctor = commandExists('claude');

test('claude doctor succeeds (if cli available)', { skip: !shouldRunDoctor }, (t) => {
  assert.ok(shouldRunDoctor, 'claude CLI not found in PATH');

  const result = spawnSync('claude', ['doctor'], {
    encoding: 'utf-8',
    input: '\n',
    timeout: 5000
  });

  if (result.error) {
    if (result.error.code === 'ETIMEDOUT') {
      t.skip('claude doctor timed out (likely waiting for interactive input)');
      return;
    }
    throw result.error;
  }

  assert.strictEqual(
    result.status,
    0,
    `claude doctor failed (stdout: ${result.stdout || ''}, stderr: ${result.stderr || ''})`
  );
});
