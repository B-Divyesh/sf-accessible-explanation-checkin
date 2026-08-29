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
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Collect student reasoning');
  await expectAccessible(page);
  await page.goto('/privacy');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Privacy');
  await expectAccessible(page);
  await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
  await page.goto('/create');
  await expectAccessible(page);
  expect(errors).toEqual([]);
});

test('navigation moves focus to the new heading and updates route metadata', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('link', { name: 'Create' }).click();
  await expect(page).toHaveURL(/\/create$/);
  await expect(page.getByRole('heading', { level: 1 })).toBeFocused();
  await expect(page.locator('#announcer')).toHaveText('Opened Create a student explanation check-in.');
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', 'https://accessible-explanation-checkin.sociobot.in/create');
  await expect(page.locator('meta[property="og:title"]')).toHaveAttribute('content', 'Create a check-in — Accessible Explanation Check-in');
  await page.goBack();
  await expect(page.getByRole('heading', { level: 1 })).toBeFocused();
  await expect(page.locator('#announcer')).toHaveText('Opened Collect student reasoning.');
});

test('every public route keeps Privacy in the primary navigation', async ({ page }) => {
  for (const route of ['/', '/demo', '/create', '/pricing', '/privacy', '/terms', '/no-such-page']) {
    await page.goto(route);
    const primaryNavigation = page.getByRole('navigation', { name: 'Primary' });
    await expect(primaryNavigation.getByRole('link', { name: 'Privacy' }), route).toHaveAttribute('href', '/privacy');
  }
});

test('unknown paths return the designed 404 with an HTTP 404 status', async ({ request, page }) => {
  const response = await request.get('/no-such-page');
  expect(response.status()).toBe(404);
  await page.goto('/no-such-page');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('That page is not available');
  await expect(page.getByRole('link', { name: 'Skip to main content' })).toHaveAttribute('href', '#main');
  await expect(page.getByRole('banner')).toBeVisible();
  await expect(page.getByRole('contentinfo')).toBeVisible();
  const legalNavigation = page.getByRole('navigation', { name: 'Legal' });
  await expect(legalNavigation.getByRole('link', { name: 'Privacy' })).toHaveAttribute('href', '/privacy');
  await expect(legalNavigation.getByRole('link', { name: 'Terms' })).toHaveAttribute('href', '/terms');
  await expect(page.locator('meta[name="description"]')).toHaveAttribute('content', /unavailable/);
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', 'https://accessible-explanation-checkin.sociobot.in/404');
  await expect(page.locator('meta[property="og:image"]')).toHaveAttribute('content', /social-classroom\.jpg$/);
  await expect(page.locator('meta[name="twitter:card"]')).toHaveAttribute('content', 'summary_large_image');
  await expect(page.getByRole('contentinfo')).toContainText('Built by Param Factory · version 1.0.0');
  await expectAccessible(page);
});

test('mobile theme and legal controls meet the 44px touch-target contract', async ({ page }, testInfo) => {
  test.skip(!testInfo.project.name.startsWith('mobile'), 'This is a 390px mobile regression check.');
  for (const route of ['/', '/demo', '/create', '/pricing', '/privacy', '/terms', '/no-such-page']) {
    await page.goto(route);
    const undersized = await page.locator('a, button, input, select, textarea').evaluateAll(elements => elements.flatMap(element => {
      const control = element as HTMLElement;
      if (getComputedStyle(control).visibility === 'hidden') return [];
      const input = control instanceof HTMLInputElement ? control : null;
      const target = input && ['checkbox', 'radio'].includes(input.type)
        ? input.closest('label') as HTMLElement | null
        : control;
      if (!target) return [];
      const box = target.getBoundingClientRect();
      if (box.width === 0 || box.height === 0 || (box.width >= 44 && box.height >= 44)) return [];
      return [{
        name: control.getAttribute('aria-label') || control.textContent?.trim() || input?.name,
        width: box.width,
        height: box.height,
      }];
    }));
    expect(undersized, route + ' has undersized controls').toEqual([]);
  }
});

test('shared footer identifies the builder and release version', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('contentinfo')).toContainText('Built by Param Factory · version 1.0.0');
});

test('plans use the production billing endpoint', async ({ page }) => {
  await page.goto('/pricing');
  await expect(page.getByRole('link', { name: 'Buy Classroom Plus through Sociobot (opens external site)' })).toHaveAttribute(
    'href',
    'https://api.sociobot.in/api/v1/products/accessible-explanation-checkin/checkout',
  );
});

test('sample demo has no serious or critical accessibility findings', async ({ page }) => {
  await page.goto('/demo');
  await expectAccessible(page);
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
