#!/usr/bin/env node
const { execSync } = require('child_process');
const path = require('path');

const installer = path.join(__dirname, '..', 'cgx-installer.sh');
const args = process.argv.slice(2).join(' ');

try {
  execSync(`bash "${installer}" ${args}`, { stdio: 'inherit' });
} catch (e) {
  process.exit(e.status || 1);
}
