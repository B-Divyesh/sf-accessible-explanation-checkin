import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, test } from 'vitest';
import playwrightConfig, { COLD_SERVER_START_TIMEOUT_MS } from '../playwright.config';

type Claim = { id: string; test: string };

describe('clean claim startup budget', () => {
  test('every browser claim uses the cold-Rust-safe Playwright server timeout', () => {
    const root = resolve(__dirname, '../..');
    const claims = JSON.parse(
      readFileSync(resolve(root, '.factory/claims.json'), 'utf8'),
    ) as Claim[];
    const packageJson = JSON.parse(
      readFileSync(resolve(root, 'package.json'), 'utf8'),
    ) as { scripts: Record<string, string> };

    const browserClaims = claims.filter(({ test: command }) =>
      command.startsWith('npm run test:claims'),
    );
    expect(browserClaims.map(({ id }) => id)).toHaveLength(16);
    expect(packageJson.scripts['test:claims']).toContain(
      '--config frontend/playwright.config.ts',
    );
    expect(packageJson.scripts['test:e2e']).toBe(
      'npm run test:e2e:desktop && npm run test:e2e:mobile',
    );
    expect(packageJson.scripts['test:e2e:desktop']).toContain(
      '--project=desktop-chromium',
    );
    expect(packageJson.scripts['test:e2e:mobile']).toContain(
      '--project=mobile-chromium',
    );
    expect(COLD_SERVER_START_TIMEOUT_MS).toBe(600_000);
    expect(playwrightConfig.webServer).toMatchObject({
      command: expect.stringContaining('cargo run --locked'),
      timeout: COLD_SERVER_START_TIMEOUT_MS,
    });
  });
});
