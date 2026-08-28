import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  retries: 0,
  reporter: 'line',
  use: {
    baseURL: 'http://127.0.0.1:8080',
    trace: 'retain-on-failure',
  },
  webServer: {
    command: 'npm run build && cargo run',
    cwd: '..',
    url: 'http://127.0.0.1:8080/health',
    reuseExistingServer: true,
    timeout: 120_000,
    env: { DATABASE_URL: 'sqlite:data/e2e.db?mode=rwc', RUST_LOG: 'warn' },
  },
  projects: [
    { name: 'desktop-chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile-chromium', use: { ...devices['iPhone 13'], browserName: 'chromium', viewport: { width: 390, height: 844 } } },
  ],
});
