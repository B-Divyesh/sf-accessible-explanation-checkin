import { expect, test } from '@playwright/test';

test('@claim:demo-isolation starts with a populated review and keeps mutations in the demo namespace', async ({ page }) => {
  const apiRequests:string[]=[];
  page.on('request', request => { if (new URL(request.url()).pathname.startsWith('/api/')) apiRequests.push(request.url()); });
  await page.goto('/?demo=1');
  await expect(page.getByText('Demo — sample data, nothing is saved')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Watershed reasoning' })).toBeVisible();
  await page.getByLabel('Clear reasoning').first().check();
  await page.getByRole('button', { name: 'Save sample review' }).first().click();
  await expect(page.getByText('Saved in demo')).toBeVisible();
  expect(apiRequests).toEqual([]);
  expect(await page.evaluate(() => ({ demo:localStorage.getItem('demo:accessible-explanation-checkin:review'), real:localStorage.getItem('recent-checkins') }))).toEqual({ demo: expect.any(String), real: null });
});

test('@claim:demo-reset restores the shipped sample', async ({ page }) => {
  await page.goto('/demo');
  await page.getByLabel('Private teacher note').first().fill('Changed only in demo');
  await page.getByRole('button', { name: 'Save sample review' }).first().click();
  await page.getByRole('button', { name: 'Reset demo' }).click();
  await expect(page.getByLabel('Private teacher note').first()).toHaveValue('Ask Maya to connect the model to the class data.');
});

test('@claim:sample-csv-export downloads each shipped sample response', async ({ page }) => {
  await page.goto('/demo');
  const download = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Download sample CSV' }).click();
  const file=await download;
  expect(file.suggestedFilename()).toBe('sample-explanation-checkin.csv');
  const content=await file.createReadStream().then(async stream => { const chunks:Buffer[]=[]; for await (const chunk of stream!) chunks.push(Buffer.from(chunk)); return Buffer.concat(chunks).toString('utf8'); });
  expect(content.split('\n')).toHaveLength(4);
  expect(content).toContain('student_name,confidence,explanation');
  expect(content).toContain('Maya Chen');
});

test('@claim:keyboard-demo is usable with a keyboard', async ({ page }) => {
  await page.goto('/demo');
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Skip to main content' })).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page.locator('main')).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('button', { name: 'Download sample CSV' })).toBeFocused();
});

test('@claim:no-account-needed creates a check-in without a sign-in step', async ({ page }) => {
  await page.goto('/demo');
  await page.goto('/create');
  await expect(page.getByLabel(/email|password|sign in/i)).toHaveCount(0);
  await page.getByLabel('Assignment name').fill('No-account proof');
  await page.getByLabel('Explanation prompt').fill('Which choice changed your conclusion and why?');
  await page.getByRole('button', { name: 'Create private links' }).click();
  await expect(page.getByRole('heading', { name: 'Keep one link. Share the other.' })).toBeVisible();
});

test('@claim:voice-retention-control offers the free one-to-seven-day schedule', async ({ page }) => {
  await page.goto('/demo');
  await page.goto('/create');
  await expect(page.locator('select[name="voice_retention_days"] option')).toHaveText(['1 day', '3 days', '7 days']);
});

test('@claim:free-response-limit shows the free limit in the creation flow', async ({ page }) => {
  await page.goto('/demo');
  await page.goto('/create');
  await expect(page.getByText('Free check-ins accept 35 responses and voice is kept for up to 7 days.')).toBeVisible();
});

test('@claim:no-automated-judgment states the product limit in the landing content', async ({ page }) => {
  await page.goto('/demo');
  await page.goto('/');
  await expect(page.getByText('It does not grade, detect AI use, proctor, or verify identity.')).toBeVisible();
});

test('@claim:offline-demo reloads after its first visit', async ({ context, page }) => {
  await page.goto('/demo');
  await page.waitForFunction(() => navigator.serviceWorker.controller !== null);
  await page.goto('/demo');
  await context.setOffline(true);
  await page.reload();
  await expect(page.getByRole('heading', { name: 'Watershed reasoning' })).toBeVisible();
  await context.setOffline(false);
});
