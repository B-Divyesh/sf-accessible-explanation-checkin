import { expect, test, type Page, type TestInfo } from '@playwright/test';

function desktopOnly(testInfo: TestInfo) {
  test.skip(testInfo.project.name.startsWith('mobile'), 'One state-changing backend fixture is sufficient for this claim.');
}

async function createCheckin(page: Page, title: string) {
  await page.goto('/create');
  await page.getByLabel('Assignment name').fill(title);
  await page.getByLabel('Explanation prompt').fill('Which choice changed your conclusion and why?');
  await page.getByRole('button', { name: 'Create private links' }).click();
  return {
    studentUrl: await page.locator('#student-link').inputValue(),
    reviewUrl: await page.locator('#review-link').inputValue(),
  };
}

async function tabTo(page: Page, selector: string) {
  for (let step = 0; step < 30; step += 1) {
    if (await page.evaluate(target => document.activeElement?.matches(target), selector)) return;
    await page.keyboard.press('Tab');
  }
  throw new Error(`Keyboard focus did not reach ${selector}`);
}

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

test('@claim:keyboard-demo lets a teacher use the sample review with a keyboard', async ({ page }) => {
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
  const student = await page.locator('#student-link').inputValue();
  const review = await page.locator('#review-link').inputValue();
  expect(student).not.toBe(review);
  expect(new URL(student).pathname).toMatch(/^\/c\/[a-f0-9]{32}$/);
  expect(new URL(review).pathname).toMatch(/^\/review\/[a-f0-9]{32}$/);
});

test('@claim:recent-links-local keeps recent review links in one browser only', async ({ browser, page }, testInfo) => {
  desktopOnly(testInfo);
  const requests: string[] = [];
  page.on('request', request => requests.push(request.url()));
  await page.goto('/demo');
  await page.goto('/create');
  await page.getByLabel('Assignment name').fill('Browser-only recent link');
  await page.getByLabel('Explanation prompt').fill('Which example changed your conclusion?');
  await page.getByRole('button', { name: 'Create private links' }).click();
  const reviewUrl = await page.locator('#review-link').inputValue();
  const saved = await page.evaluate(() => JSON.parse(localStorage.getItem('recent-checkins') || '[]'));
  expect(saved).toHaveLength(1);
  expect(saved[0]).toMatchObject({ title: 'Browser-only recent link', review: reviewUrl });
  expect([...new Set(requests.map(url => new URL(url).origin))]).toEqual(['http://127.0.0.1:8080']);

  const freshContext = await browser.newContext({ baseURL: 'http://127.0.0.1:8080' });
  try {
    const freshPage = await freshContext.newPage();
    await freshPage.goto('/create');
    await expect(freshPage.getByText('Your private review links will appear here after you create a check-in.')).toBeVisible();
    expect(await freshPage.evaluate(() => localStorage.getItem('recent-checkins'))).toBeNull();
  } finally {
    await freshContext.close();
  }
});

test('@claim:voice-retention-control applies the selected free voice schedule', async ({ page }, testInfo) => {
  desktopOnly(testInfo);
  await page.goto('/demo');
  await page.goto('/create');
  await expect(page.locator('select[name="voice_retention_days"] option')).toHaveText(['1 day', '3 days', '7 days']);
  const response = await page.request.post('/api/checkins', { data: {
    title: 'Retention proof',
    prompt: 'Explain the choice you made.',
    voice_retention_days: 3,
  }});
  expect(response.status()).toBe(201);
  const created = await response.json();
  await page.goto(`/c/${created.student_token}`);
  await expect(page.getByText('it will delete automatically 3 days after submission', { exact: false })).toBeVisible();
});

test('@claim:free-response-limit enforces 35 responses under concurrent submissions', async ({ page }, testInfo) => {
  desktopOnly(testInfo);
  await page.goto('/demo');
  const create = await page.request.post('/api/checkins', { data: {
    title: 'Concurrent limit proof',
    prompt: 'Explain one choice.',
    voice_retention_days: 1,
  }});
  const { student_token: student } = await create.json();
  const responses = await Promise.all(Array.from({ length: 40 }, (_, number) => page.request.post(`/api/checkins/${student}/submissions`, { data: {
    student_name: `Student ${number}`,
    explanation_text: 'I compared both choices.',
    confidence: 3,
  }})));
  expect(responses.filter(response => response.status() === 201)).toHaveLength(35);
  expect(responses.filter(response => response.status() === 409)).toHaveLength(5);
  const checkin = await page.request.get(`/api/checkins/${student}`);
  expect(await checkin.json()).toMatchObject({ submissions: 35, max_submissions: 35, open: false });
});

test('@claim:no-automated-judgment returns only student input and teacher-authored review fields', async ({ page }, testInfo) => {
  desktopOnly(testInfo);
  await page.goto('/demo');
  const create = await page.request.post('/api/checkins', { data: { title: 'No scoring proof', prompt: 'Explain one choice.', voice_retention_days: 1 }});
  const created = await create.json();
  await page.request.post(`/api/checkins/${created.student_token}/submissions`, { data: {
    student_name: 'Alex', explanation_text: 'I used the second example.', confidence: 2,
  }});
  const review = await page.request.get(`/api/reviews/${created.review_token}`);
  const payload = await review.json();
  const keys = JSON.stringify(payload).toLowerCase();
  for (const automatedField of ['grade', 'ai_score', 'identity_score', 'proctor_score', 'misconduct_score']) {
    expect(keys).not.toContain(`"${automatedField}"`);
  }
  expect(payload.submissions[0]).toMatchObject({
    student_name: 'Alex', explanation_text: 'I used the second example.', confidence: 2,
    teacher_tags: [], teacher_note: '', follow_up: false,
  });
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

test('@claim:student-keyboard-flow submits every required student field using only the keyboard', async ({ page }, testInfo) => {
  desktopOnly(testInfo);
  await page.goto('/demo');
  await page.goto('/create');
  await tabTo(page, 'input[name="title"]');
  await page.keyboard.type('Keyboard path proof');
  await tabTo(page, 'textarea[name="prompt"]');
  await page.keyboard.type('Which step changed your conclusion?');
  await tabTo(page, 'button[type="submit"]');
  await page.keyboard.press('Enter');
  await expect(page.locator('#student-link')).toBeVisible();
  const studentUrl = await page.locator('#student-link').inputValue();

  await page.goto(studentUrl);
  await tabTo(page, 'input[name="student_name"]');
  await page.keyboard.type('Taylor');
  await tabTo(page, 'textarea[name="explanation_text"]');
  await page.keyboard.type('I compared the examples and changed my answer.');
  await tabTo(page, 'input[name="confidence"]');
  await page.keyboard.press('ArrowRight');
  await page.keyboard.press('ArrowRight');
  await page.keyboard.press('ArrowRight');
  await tabTo(page, 'button[type="submit"]');
  await page.keyboard.press('Enter');
  await expect(page.getByRole('heading', { name: 'Your check-in receipt' })).toBeVisible();
  await expect(page.getByText('I compared the examples and changed my answer.')).toBeVisible();
});

test('@claim:student-review-workflow carries the explanation into a saved teacher review and free outputs', async ({ page }, testInfo) => {
  desktopOnly(testInfo);
  await page.goto('/demo');
  const { studentUrl, reviewUrl } = await createCheckin(page, 'Review workflow proof');
  await page.goto(studentUrl);
  await page.getByLabel('Your name').fill('Morgan Lee');
  await page.getByLabel('Write your explanation').fill('The comparison table changed my conclusion.');
  await page.getByLabel('Mostly').check();
  await page.getByRole('button', { name: 'Send my explanation' }).click();
  await expect(page.getByRole('heading', { name: 'Your check-in receipt' })).toBeVisible();
  await expect(page.getByText('The comparison table changed my conclusion.')).toBeVisible();
  await page.evaluate(() => { (window as Window & { printCalled?: boolean }).printCalled = false; window.print = () => { (window as Window & { printCalled?: boolean }).printCalled = true; }; });
  await page.getByRole('button', { name: 'Print or save PDF' }).click();
  expect(await page.evaluate(() => (window as Window & { printCalled?: boolean }).printCalled)).toBe(true);

  await page.goto(reviewUrl);
  await expect(page.getByRole('heading', { name: 'Morgan Lee' })).toBeVisible();
  await expect(page.getByText('Confidence 4/5')).toBeVisible();
  await page.getByLabel('Uses evidence').check();
  await page.getByLabel('Private teacher note').fill('Ask Morgan to show the table.');
  await page.getByLabel('Mark for follow-up').check();
  await page.getByRole('button', { name: 'Save review' }).click();
  await expect(page.getByText('Saved', { exact: true })).toBeVisible();
  await page.reload();
  await expect(page.getByLabel('Uses evidence')).toBeChecked();
  await expect(page.getByLabel('Private teacher note')).toHaveValue('Ask Morgan to show the table.');
  await expect(page.getByLabel('Mark for follow-up')).toBeChecked();
  const download = page.waitForEvent('download');
  await page.getByRole('link', { name: 'Export CSV' }).click();
  const csv = await download;
  const content = await csv.createReadStream().then(async stream => { const chunks: Buffer[] = []; for await (const chunk of stream!) chunks.push(Buffer.from(chunk)); return Buffer.concat(chunks).toString('utf8'); });
  expect(content).toContain('Morgan Lee');
  expect(content).toContain('Uses evidence');
  expect(content).toContain('Ask Morgan to show the table.');
});

test('@claim:privacy-request-boundary keeps the demo and classroom flow on the product origin', async ({ page }, testInfo) => {
  desktopOnly(testInfo);
  const requests: string[] = [];
  page.on('request', request => requests.push(request.url()));
  await page.goto('/demo');
  const { studentUrl, reviewUrl } = await createCheckin(page, 'Privacy request proof');
  await page.goto(studentUrl);
  await page.getByLabel('Your name').fill('Casey');
  await page.getByLabel('Write your explanation').fill('I checked the evidence twice.');
  await page.getByLabel('In between').check();
  await page.getByRole('button', { name: 'Send my explanation' }).click();
  await page.goto(reviewUrl);
  expect([...new Set(requests.map(url => new URL(url).origin))]).toEqual(['http://127.0.0.1:8080']);
  expect(requests.some(url => /analytics|doubleclick|openai|google-analytics|segment/i.test(url))).toBe(false);
});

test('@claim:billing-license-fixture handles an active and then revoked license verdict', async ({ page }) => {
  let valid = true;
  await page.route('https://api.sociobot.in/api/v1/products/accessible-explanation-checkin/verify**', route => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ valid, reason: valid ? 'ok' : 'revoked' }),
  }));
  await page.goto('/demo');
  await page.goto('/pricing');
  await page.getByLabel('License token').fill('recorded-fixture-license');
  await page.getByRole('button', { name: 'Verify license' }).click();
  await expect(page.getByText('Classroom Plus is active on this device.')).toBeVisible();
  valid = false;
  await page.getByRole('button', { name: 'Verify license' }).click();
  await expect(page.getByText('This license is not active. Check the token or buy Classroom Plus.')).toBeVisible();
  await page.goto('/create');
  await expect(page.locator('select[name="voice_retention_days"] option')).toHaveText(['1 day', '3 days', '7 days']);
  await expect(page.getByRole('button', { name: 'Create private links' })).toBeVisible();
});

test('@claim:refund-license-contract treats a recorded refunded license as revoked', async ({ page }) => {
  await page.route('https://api.sociobot.in/api/v1/products/accessible-explanation-checkin/verify**', route => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ valid: false, reason: 'revoked', event: 'refund' }),
  }));
  await page.goto('/demo');
  await page.goto('/pricing');
  await expect(page.getByText('Sociobot/Dodo is the merchant of record.')).toBeVisible();
  await expect(page.getByText('Refunds are requested there; a refunded license becomes inactive here.')).toBeVisible();
  await page.getByLabel('License token').fill('recorded-refunded-license');
  await page.getByRole('button', { name: 'Verify license' }).click();
  await expect(page.getByText('This license is not active. Check the token or buy Classroom Plus.')).toBeVisible();
  await page.goto('/create');
  await expect(page.locator('select[name="voice_retention_days"] option')).toHaveText(['1 day', '3 days', '7 days']);
  await expect(page.getByRole('button', { name: 'Create private links' })).toBeVisible();
});

test('@claim:external-checkout verifies the live $39 checkout before leaving the product', async ({ page, request }, testInfo) => {
  desktopOnly(testInfo);
  const checkoutUrl = 'https://api.sociobot.in/api/v1/products/accessible-explanation-checkin/checkout';
  const catalogResponse = await request.get('https://api.sociobot.in/api/v1/products');
  expect(catalogResponse.status()).toBe(200);
  const catalog = await catalogResponse.json();
  expect(catalog.data).toContainEqual(expect.objectContaining({
    slug: 'accessible-explanation-checkin',
    name: 'Accessible Explanation Check-in Classroom Plus',
    price_minor: 3900,
    currency: 'USD',
    checkout_url: checkoutUrl,
  }));

  // This GET creates only an unpaid checkout session. Do not follow it or submit payment details.
  const liveCheckout = await request.get(checkoutUrl, { maxRedirects: 0 });
  expect(liveCheckout.status()).toBe(303);
  expect(liveCheckout.headers().location).toMatch(/^https:\/\/checkout\.dodopayments\.com\/session\/cks_[A-Za-z0-9]+$/);

  await page.route(checkoutUrl, route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html lang="en"><title>Sociobot checkout fixture</title><body><h1>Sociobot checkout fixture</h1></body></html>',
  }));
  await page.goto('/demo');
  await page.goto('/pricing');
  await expect(page.getByRole('heading', { name: '$39 one time' })).toBeVisible();
  const checkout = page.getByRole('link', { name: 'Buy Classroom Plus through Sociobot (opens external site)' });
  await expect(checkout).toHaveAttribute('href', checkoutUrl);
  await checkout.click();
  await expect(page).toHaveURL(checkoutUrl);
  await expect(page.getByRole('heading', { name: 'Sociobot checkout fixture' })).toBeVisible();
});
