import { defineConfig, devices } from '@playwright/test';

// A fresh verifier checkout has no Rust target directory. Keep the complete
// dependency download and cold backend compile inside an explicit ten-minute
// server-start budget; the previous two-minute budget expired on slower
// workers before Playwright could run the first claim.
export const COLD_SERVER_START_TIMEOUT_MS = 10 * 60_000;

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  retries: 0,
  workers: 1,
  reporter: 'line',
  use: {
    baseURL: 'http://127.0.0.1:8080',
    trace: 'retain-on-failure',
  },
  webServer: {
    command: 'npm run build && cargo run --locked',
    cwd: '..',
    url: 'http://127.0.0.1:8080/health',
    reuseExistingServer: true,
    timeout: COLD_SERVER_START_TIMEOUT_MS,
    env: { DATABASE_URL: 'sqlite:data/e2e.db?mode=rwc', RUST_LOG: 'warn' },
  },
  projects: [
    { name: 'desktop-chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile-chromium', use: { ...devices['iPhone 13'], browserName: 'chromium', viewport: { width: 390, height: 844 } } },
  ],
});
