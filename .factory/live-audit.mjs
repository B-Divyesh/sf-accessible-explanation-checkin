import { mkdir, writeFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { chromium } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const base = process.env.AUDIT_BASE_URL || 'https://accessible-explanation-checkin.sociobot.in';
const evidencePrefix = process.env.AUDIT_EVIDENCE_PREFIX || 'repair-3';
const evidenceDir = new URL('./evidence/', import.meta.url);
await mkdir(evidenceDir, { recursive: true });

const expected = new Map([
  ['/', { status: 200, h1: 'Collect student reasoning', canonical: '/' }],
  ['/demo', { status: 200, h1: 'Watershed reasoning', canonical: '/demo' }],
  ['/create', { status: 200, h1: 'Create a student explanation check-in', canonical: '/create' }],
  ['/pricing', { status: 200, h1: 'Plans and prices', canonical: '/pricing' }],
  ['/privacy', { status: 200, h1: 'Privacy', canonical: '/privacy' }],
  ['/terms', { status: 200, h1: 'Terms', canonical: '/terms' }],
  ['/no-such-page', { status: 404, h1: 'That page is not available', canonical: '/404' }],
]);

const browser = await chromium.launch();
const context = await browser.newContext({ viewport: { width: 390, height: 844 }, colorScheme: 'light', reducedMotion: 'reduce' });
const page = await context.newPage();
const consoleErrors = [];
page.on('console', message => { if (message.type() === 'error') consoleErrors.push({ text: message.text(), url: message.location().url }); });
page.on('pageerror', error => consoleErrors.push({ text: error.message, url: page.url() }));
const routeResults = [];
const darkThemeResults = [];

for (const [route, wanted] of expected) {
  const response = await page.goto(`${base}${route}`, { waitUntil: 'networkidle' });
  assert.equal(response?.status(), wanted.status, `${route} status`);
  assert.equal(await page.locator('html').getAttribute('lang'), 'en', `${route} language`);
  assert.equal(await page.locator('h1').count(), 1, `${route} h1 count`);
  assert.equal((await page.locator('h1').innerText()).trim(), wanted.h1, `${route} h1`);
  assert.equal(await page.locator('main').count(), 1, `${route} main count`);
  assert.ok((await page.title()).length <= 60, `${route} title length`);
  assert.equal(await page.locator('link[rel="canonical"]').getAttribute('href'), `${base}${wanted.canonical}`, `${route} canonical`);
  assert.ok(await page.locator('meta[name="description"]').getAttribute('content'), `${route} description`);
  assert.ok(await page.locator('meta[property="og:image"]').getAttribute('content'), `${route} social image`);
  const primaryNavigation = page.getByRole('navigation', { name: 'Primary' });
  assert.equal(await primaryNavigation.getByRole('link', { name: 'Privacy' }).count(), 1, `${route} primary privacy link`);
  assert.equal(await primaryNavigation.getByRole('link', { name: 'Privacy' }).isVisible(), true, `${route} visible primary privacy link`);
  assert.ok(await page.getByRole('link', { name: 'Terms' }).count() >= 1, `${route} terms link`);
  assert.ok((await page.getByRole('contentinfo').innerText()).includes('Built by Param Factory · version 1.0.0'), `${route} footer identity`);

  const undersized = await page.locator('a, button, input, select, textarea').evaluateAll(elements => elements.flatMap(element => {
    const control = element;
    if (getComputedStyle(control).visibility === 'hidden') return [];
    const input = control instanceof HTMLInputElement ? control : null;
    const target = input && ['checkbox', 'radio'].includes(input.type) ? input.closest('label') : control;
    if (!target) return [];
    const box = target.getBoundingClientRect();
    return box.width && box.height && (box.width < 44 || box.height < 44)
      ? [{ name: control.getAttribute('aria-label') || control.textContent?.trim() || input?.name, width: box.width, height: box.height }]
      : [];
  }));
  assert.deepEqual(undersized, [], `${route} touch targets`);
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth), false, `${route} horizontal overflow`);

  const axe = await new AxeBuilder({ page }).analyze();
  const severe = axe.violations.filter(violation => ['serious', 'critical'].includes(violation.impact || ''));
  assert.deepEqual(severe, [], `${route} serious/critical axe findings`);
  if (route === '/no-such-page') {
    await page.screenshot({ path: new URL(`./evidence/${evidencePrefix}-live-404-mobile.png`, import.meta.url).pathname, fullPage: true });
  }
  await page.evaluate(() => { document.documentElement.style.fontSize = '32px'; });
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth), false, `${route} 200% text overflow`);

  routeResults.push({ route, status: wanted.status, title: await page.title(), axeSeriousCritical: severe.length, undersizedTargets: undersized.length });
}

const darkContext = await browser.newContext({ viewport: { width: 390, height: 844 }, colorScheme: 'dark', reducedMotion: 'reduce' });
const darkPage = await darkContext.newPage();
for (const [route, wanted] of expected) {
  const response = await darkPage.goto(`${base}${route}`, { waitUntil: 'networkidle' });
  assert.equal(response?.status(), wanted.status, `${route} dark-theme status`);
  if (route !== '/no-such-page') {
    await darkPage.evaluate(() => { document.documentElement.dataset.theme = 'dark'; });
  }
  const axe = await new AxeBuilder({ page: darkPage }).analyze();
  const severe = axe.violations.filter(violation => ['serious', 'critical'].includes(violation.impact || ''));
  assert.deepEqual(severe, [], `${route} dark-theme serious/critical axe findings`);
  darkThemeResults.push({ route, axeSeriousCritical: severe.length });
}
await darkContext.close();

const crawledLinks = new Map();
for (const [route, wanted] of expected) {
  if (wanted.status !== 200) continue;
  await page.goto(`${base}${route}`, { waitUntil: 'networkidle' });
  for (const link of await page.locator('a[href]').evaluateAll(anchors => anchors.map(anchor => ({
    href: anchor.href,
    name: anchor.getAttribute('aria-label') || anchor.textContent?.trim() || '',
  })))) {
    if (link.href.startsWith('mailto:')) continue;
    crawledLinks.set(link.href, link.name);
  }
}
for (const [href, name] of crawledLinks) {
  const url = new URL(href);
  if (url.origin !== base) {
    assert.match(name, /opens external site/i, `${href} external-link label`);
    continue;
  }
  const response = await fetch(url, { redirect: 'manual' });
  assert.ok(response.status >= 200 && response.status < 400, `${href} link status ${response.status}`);
}

await page.goto(base, { waitUntil: 'networkidle' });
await page.locator('a[href="/create"]').click();
await page.waitForURL(`${base}/create`);
await page.waitForFunction(() => document.querySelector('h1') === document.activeElement);
const forwardAnnouncement = await page.locator('#announcer').innerText();
assert.equal(forwardAnnouncement, 'Opened Create a student explanation check-in.');
await page.goBack();
await page.waitForFunction(() => document.querySelector('h1') === document.activeElement);
const backAnnouncement = await page.locator('#announcer').innerText();
assert.equal(backAnnouncement, 'Opened Collect student reasoning.');

const demoContext = await browser.newContext({ viewport: { width: 390, height: 844 }, serviceWorkers: 'allow' });
const demo = await demoContext.newPage();
const demoRequests = [];
demo.on('request', request => demoRequests.push(request.url()));
await demo.goto(`${base}/?demo=1`, { waitUntil: 'networkidle' });
assert.equal(await demo.title(), 'Demo — Accessible Explanation Check-in');
assert.equal(await demo.locator('article.submission').count(), 3);
await demo.getByText('Demo — sample data, nothing is saved').waitFor();
await demo.getByLabel('Private teacher note').first().fill('Live demo isolation check');
await demo.getByRole('button', { name: 'Save sample review' }).first().click();
assert.deepEqual(await demo.evaluate(() => ({
  demo: Boolean(localStorage.getItem('demo:accessible-explanation-checkin:review')),
  real: localStorage.getItem('recent-checkins'),
})), { demo: true, real: null });
assert.equal(demoRequests.some(url => new URL(url).pathname.startsWith('/api/')), false, 'demo API isolation');
await demo.getByRole('button', { name: 'Reset demo' }).click();
assert.equal(await demo.getByLabel('Private teacher note').first().inputValue(), 'Ask Maya to connect the model to the class data.');
await demo.waitForFunction(() => navigator.serviceWorker.controller !== null);
await demo.reload({ waitUntil: 'networkidle' });
await demoContext.setOffline(true);
await demo.reload({ waitUntil: 'domcontentloaded' });
await demo.getByRole('heading', { name: 'Watershed reasoning' }).waitFor();
await demoContext.setOffline(false);
await demo.screenshot({ path: new URL(`./evidence/${evidencePrefix}-live-demo-mobile.png`, import.meta.url).pathname, fullPage: true });
await demoContext.close();

const flowContext = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const flow = await flowContext.newPage();
const workflowRequests = [];
flow.on('request', request => workflowRequests.push(request.url()));
await flow.goto(`${base}/create`);
await flow.getByLabel('Assignment name').fill('Live release verification');
await flow.getByLabel('Explanation prompt').fill('Which example changed your conclusion, and why?');
await flow.getByRole('button', { name: 'Create private links' }).click();
const studentUrl = await flow.locator('#student-link').inputValue();
const reviewUrl = await flow.locator('#review-link').inputValue();
assert.match(studentUrl, new RegExp(`^${base}/c/[a-f0-9]{32}$`));
assert.match(reviewUrl, new RegExp(`^${base}/review/[a-f0-9]{32}$`));
await flow.goto(studentUrl);
await flow.getByLabel('Your name').fill('Release verifier');
await flow.getByLabel('Write your explanation').fill('I compared the two examples and used the second result.');
await flow.getByLabel('Mostly').check();
await flow.getByRole('button', { name: 'Send my explanation' }).click();
await flow.getByRole('heading', { name: 'Your check-in receipt' }).waitFor();
await flow.goto(reviewUrl);
await flow.getByRole('heading', { name: 'Release verifier' }).waitFor();
await flow.getByLabel('Uses evidence').check();
await flow.getByLabel('Private teacher note').fill('Live review save verified.');
await flow.getByLabel('Mark for follow-up').check();
await flow.getByRole('button', { name: 'Save review' }).click();
await flow.getByText('Saved', { exact: true }).waitFor();
await flow.reload();
assert.equal(await flow.getByLabel('Uses evidence').isChecked(), true);
assert.equal(await flow.getByLabel('Private teacher note').inputValue(), 'Live review save verified.');
assert.deepEqual([...new Set(workflowRequests.map(url => new URL(url).origin))], [base]);
await flowContext.close();

const checkoutUrl = 'https://api.sociobot.in/api/v1/products/accessible-explanation-checkin/checkout';
const catalogResponse = await fetch('https://api.sociobot.in/api/v1/products');
assert.equal(catalogResponse.status, 200);
const catalog = await catalogResponse.json();
assert.ok(catalog.data.some(product => product.slug === 'accessible-explanation-checkin' && product.price_minor === 3900 && product.currency === 'USD'));
const checkoutResponse = await fetch(checkoutUrl, { redirect: 'manual' });
assert.equal(checkoutResponse.status, 303);
assert.match(checkoutResponse.headers.get('location') || '', /^https:\/\/checkout\.dodopayments\.com\/session\/cks_[A-Za-z0-9]+$/);

const healthResponse = await fetch(`${base}/health`);
assert.equal(healthResponse.status, 200);
const health = await healthResponse.json();
assert.match(health.build_sha, /^[a-f0-9]{40}$/);
const homeResponse = await fetch(base);
for (const header of ['content-security-policy', 'strict-transport-security', 'permissions-policy', 'x-content-type-options', 'referrer-policy']) {
  assert.ok(homeResponse.headers.get(header), `missing ${header}`);
}

const unexpectedConsoleErrors = consoleErrors.filter(error => !(error.text.includes('status of 404') && error.url.includes('/no-such-page')));
assert.deepEqual(unexpectedConsoleErrors, [], 'browser console errors');
const report = {
  checkedAt: new Date().toISOString(),
  base,
  buildSha: health.build_sha,
  routes: routeResults,
  darkThemeRoutes: darkThemeResults,
  crawledLinks: crawledLinks.size,
  focus: { forward: 'h1', back: 'h1', forwardAnnouncement, backAnnouncement },
  demo: { entry: '/?demo=1', sampleResponses: 3, isolatedStorage: true, reset: true, apiRequests: 0, offlineReload: true },
  workflow: { created: true, submitted: true, reviewed: true, reloadedSavedReview: true, origins: [base] },
  checkout: { catalogPriceMinor: 3900, currency: 'USD', status: 303, destination: 'checkout.dodopayments.com' },
  securityHeaders: ['content-security-policy', 'strict-transport-security', 'permissions-policy', 'x-content-type-options', 'referrer-policy'],
  consoleErrors: unexpectedConsoleErrors,
};
await writeFile(new URL(`./evidence/${evidencePrefix}-live-check.json`, import.meta.url), `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify(report, null, 2));
await context.close();
await browser.close();
