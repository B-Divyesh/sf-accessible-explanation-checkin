import { expect, test } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

async function expectAccessible(page: import('@playwright/test').Page) {
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations.filter(v => ['serious', 'critical'].includes(v.impact || ''))).toEqual([]);
  await expect(page.locator('h1')).toHaveCount(1);
  await expect(page.locator('main')).toHaveCount(1);
}

test('landing and legal screens are semantic and console-clean', async ({ page }) => {
  const errors:string[]=[];
  page.on('console', message => { if (message.type() === 'error') errors.push(`${message.text()} ${message.location().url}`); });
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toContainText('Hear the thinking');
  await expectAccessible(page);
  await page.goto('/privacy');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Privacy');
  await expectAccessible(page);
  await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
  await page.goto('/create');
  await expectAccessible(page);
  expect(errors).toEqual([]);
});

test('mobile theme and legal controls meet the 44px touch-target contract', async ({ page }, testInfo) => {
  test.skip(!testInfo.project.name.startsWith('mobile'), 'This is a 390px mobile regression check.');
  await page.goto('/privacy');
  for (const control of [
    page.getByRole('button', { name: 'Change color theme' }),
    page.getByRole('link', { name: 'Privacy', exact: true }),
    page.getByRole('link', { name: 'Terms', exact: true }),
  ]) {
    const box = await control.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.width).toBeGreaterThanOrEqual(44);
    expect(box!.height).toBeGreaterThanOrEqual(44);
  }
});

test('plans use the production billing endpoint', async ({ page }) => {
  await page.goto('/pricing');
  await expect(page.getByRole('link', { name: 'Buy Classroom Plus' })).toHaveAttribute(
    'href',
    'https://api.sociobot.in/api/v1/products/accessible-explanation-checkin/checkout',
  );
});

test('teacher creates, student explains, and teacher reviews', async ({ page }) => {
  await page.goto('/create');
  await page.getByLabel('Assignment name').fill('Watershed reasoning');
  await page.getByLabel('Explanation prompt').fill('Which step changed your conclusion, and why?');
  await page.getByRole('button', { name: 'Create private links' }).click();
  const studentUrl=await page.locator('#student-link').inputValue();
  const reviewUrl=await page.locator('#review-link').inputValue();

  await page.goto(studentUrl);
  await page.getByLabel('Your name').fill('Sam');
  await page.getByLabel('Write your explanation').fill('I compared the two runoff paths and changed my conclusion.');
  await page.getByLabel('Mostly').check();
  await expectAccessible(page);
  await page.getByRole('button', { name: 'Send my explanation' }).click();
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Your check-in receipt');
  await expect(page.getByText('I compared the two runoff paths')).toBeVisible();

  await page.goto(reviewUrl);
  await expect(page.getByRole('heading', { name: 'Sam' })).toBeVisible();
  await page.getByLabel('Clear reasoning').check();
  await page.getByLabel('Private teacher note').fill('Ask Sam to share the comparison.');
  await page.getByLabel('Mark for follow-up').check();
  await page.getByRole('button', { name: 'Save review' }).click();
  await expect(page.getByText('Saved', { exact: true })).toBeVisible();
  await expectAccessible(page);
  const download = page.waitForEvent('download');
  await page.getByRole('link', { name: 'Export CSV' }).click();
  expect((await download).suggestedFilename()).toBe('explanation-checkin.csv');
});
