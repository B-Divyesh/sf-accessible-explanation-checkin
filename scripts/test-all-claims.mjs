import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const claims = JSON.parse(readFileSync(resolve(root, '.factory/claims.json'), 'utf8'));
const ids = new Set();

for (const claim of claims) {
  if (!claim.id || !claim.claim || !claim.where || !claim.test || !claim.sandbox) {
    throw new Error('Every claim needs id, claim, where, test, and sandbox fields.');
  }
  if (ids.has(claim.id)) throw new Error(`Duplicate claim id: ${claim.id}`);
  ids.add(claim.id);
  process.stdout.write(`\n@claim:${claim.id}\n$ ${claim.test}\n`);
  const result = spawnSync(claim.test, { cwd: root, env: process.env, shell: true, stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

process.stdout.write(`\nPASS: ${claims.length} claim commands completed.\n`);
