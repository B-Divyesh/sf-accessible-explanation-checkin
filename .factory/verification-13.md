# Independent verification 13 — FAIL

- Verified UTC: 2026-08-30
- Candidate commit: `1e959a3891a2ffe011116f9f3648d643cd80a748`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Result: **FAIL — do not release**

## First-read result

Cold desktop and 390px mobile visits plainly say what the product does
("Collect student reasoning"), for whom (teachers needing a low-stakes
check-in), and what to do first (the visible **Try it with sample data**
button, with "Open a populated teacher review; nothing is saved."). The button
is one click away and the demo opens a populated three-response teacher review.
This acceptance criterion passes.

## Release-blocking findings

### Critical — live production topology is unsafe for SQLite private records

The candidate is live: both `/health` and the root ETag identify
`1e959a3891a2ffe011116f9f3648d643cd80a748`. However, the mandatory live
topology gate fails:

```text
$ npm run verify:live-topology
ERROR: live topology check failed: expected minReplicas=maxReplicas=1; observed minReplicas=1 maxReplicas=3
```

Fresh Azure control-plane inspection confirms the cause, not a transient edge
response:

- latest and ready revision: `sf-accessible-explanation-9c1a54--0000103`
- image: `.../sf-accessible-explanation-9c1a54:1e959a3891a2`
- `minReplicas: 1`, `maxReplicas: 3`
- `volumes: null`, and the `app` container has `volumeMounts: null`
- two ready/running app replicas were returned by `az containerapp replica list`

This violates the documented one-writer SQLite deployment contract and the
`durable-deployment-policy` claim. Concurrent replicas without the required
Azure File `/app/data` mount can serve divergent private check-in data and
lose records on replacement. It is a release blocker.

### Major — mobile 200% text resizing causes horizontal overflow

On a fresh 390px Chromium visit to `/privacy`, setting the root font size to
32px produces `clientWidth: 390` and `scrollWidth: 550`. The overflowing
element is the header `nav` (right edge `550.36px`); its Privacy link and theme
button are outside the viewport. This fails the required 200% text-resize
check. The same assertion aborted the independent live audit at
`/privacy 200% text overflow`.

## Claim verification

`.factory/claims.json` exists and contains 25 claims. I installed with
`npm ci` (86 packages, 0 reported vulnerabilities) and invoked every listed
command through `npm run test:all-claims` from the demo-backed clean checkout.
The first 24 claim commands reached and passed their asserted demo, storage,
voice, privacy, licensing, and runtime-policy tests. The 25th claim,
`durable-deployment-policy`, is **FAIL** because its required final command
`npm run verify:live-topology` fails with the evidence above. A single failing
claim is release-blocking.

## Other verification evidence

- `npm test`: PASS — TypeScript, 5 Vitest tests, 13 Rust tests, and deployment
  fixture tests.
- `npm run build`: PASS — JS 38.93 kB raw / 12.43 kB gzip; CSS 19.30 kB raw /
  5.16 kB gzip; well below the static bundle budgets.
- `cargo fmt --all -- --check`, strict `cargo clippy`, and
  `cargo build --release --locked`: PASS.
- `npm run test:e2e`: PASS; the final Playwright run recorded `status: passed`
  for desktop and 390px mobile suites.
- Live normal and invalid API paths: invalid create and invalid submission both
  return 400 with actionable errors; valid create returns 201 with distinct
  tokens, valid student submission returns 201, and the private review returns
  the response.
- Live rate limiting: 150 same-client GETs produced 130 404 and 20 429
  responses. The first 429 was request 129 and included `Retry-After: 0` and
  `Cache-Control: private, no-store`; observed burst allowance was about 128
  requests (the configured burst is 120, with refill during the sequential
  run).
- Live demo request log contained only the product origin; keyboard testing
  reached the skip link and then `<main>`, with a visible `3px` focus outline.
  Axe on the live demo found no serious/critical violations and the browser
  console had no errors.
- Live response headers include CSP with `frame-ancestors 'none'`, HSTS,
  `nosniff`, `no-referrer`, and a permissions policy. Hashed assets are
  immutable for one year; HTML is revalidated.
- Fresh mobile Lighthouse: Performance 99, Accessibility 100, Best Practices
  100, SEO 100; LCP 1134ms and CLS 0. These scores do not override the explicit
  200%-text failure above.

## Required remediation

Deploy through the durable deployment wrapper so the actual Container App has
exactly one active/running replica, `minReplicas=maxReplicas=1`, the
`checkin-data` Azure File volume mounted at `/app/data`, and then rerun the
live topology and cross-revision durability checks. Also make the header
responsive at 200% text size on a 390px viewport (without hiding essential
navigation or allowing horizontal scrolling). Re-run all claim commands after
the deployment is corrected.
