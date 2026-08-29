# Independent verification 6 — FAIL

**Candidate:** `976328637bdfe5cdec53afa4e4303882351ef760`
**Live URL:** https://accessible-explanation-checkin.sociobot.in
**Checked:** 2026-08-29

## Verdict

**FAIL — release blocking.** The live deployment reports the candidate SHA in
both `/health` and the root ETag, but it serves at least two isolated backend
replicas. Private records are present only on half of independent requests.

## First read

The cold live landing page plainly says it collects student reasoning, that it
is for teachers needing a low-stakes check-in, and instructs the visitor to
**Try it with sample data**. The adjacent outcome is “Open a populated teacher
review; nothing is saved.” This passes the first-read and one-click demo test.

## Release-blocking findings

### Critical: private records split between live replicas

A fresh live API flow created a check-in (201) with valid 32-character student
and review tokens. Twenty-four concurrent student-link reads returned **12 ×
200 and 12 × 404**. A student submission returned 201, but the first teacher
review request returned 404; 24 concurrent review reads again returned **12 ×
200 and 12 × 404**. The receipt request returned 404. A teacher therefore
cannot reliably open a private link or see submitted work.

Source and fixture tests require one Azure File-backed SQLite writer. The actual
live behavior proves that configuration is not effective. Do not release until
the actual Container App has exactly one active/running replica with durable
`/app/data`, followed by a repeat of these cross-connection reads and a real
new-revision persistence check.

### High: live rate-limit allowance is duplicated

The source config has a 120-request burst. One forwarded client made 160
unknown-token API reads and received **160 × 404, 0 × 429**. At 300 concurrent
reads it received **240 × 404 and 60 × 429**; every 429 carried
`Retry-After: 0`. A different client stayed unblocked. The observed allowance
is **240**, consistent with two independent 120-request limiters, not the
intended one-writer allowance.

## Claims and local gates

After `npm ci`, all commands from `.factory/claims.json` passed: the 14 browser
claims each used the local demo entry point, the two Rust claims passed, and
runtime/deployment-policy claims passed (18/18). `npm test`, `npm run build`,
and `npm run test:e2e` passed (46 Playwright tests). Formatting, clippy,
deployment helper, container identity, and non-root runtime checks passed.
Docker could not be built because this environment has no Docker client.

Exact production build bundle: JS 38.78 kB raw / 12.48 kB gzip; CSS 19.30 kB
raw / 5.16 kB gzip.

## Live checks that passed

- Seven routes plus real 404 at 390 px, light/dark: zero serious/critical axe
  findings, undersized controls, horizontal overflow, console errors, or page
  errors.
- Keyboard routing focuses and announces the H1. Demo resets, has three sample
  records, uses `demo:` storage, sends no API requests, and reloads offline.
- Browser request logging saw only the product origin: no model, analytics,
  advertising, remote font, or third-party script request.
- CSP, HSTS, Permissions Policy, `nosniff`, no-referrer, request ID, immutable
  assets, and private `no-store` bearer/API caching were present.
- Catalog price is $39 USD and Sociobot checkout 303s to Dodo. No account is
  required, so Entra is not applicable.

## Evidence

- `.factory/evidence/verification-6-live-check.json`
- `.factory/evidence/verification-6-server-boundaries.json`
- `.factory/evidence/verification-6-live-demo-mobile.png`
- `.factory/evidence/verification-6-live-404-mobile.png`
