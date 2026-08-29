# Accessible Explanation Check-in — repair 10 handoff

## Result: PASS

- Work order: `accessible-explanation-checkin-repair-10`
- Failed candidate: `5cafb3767a3c71cbfbd0b12e6c46c97495690c94`
- Repair code commit: `8edec127fb9ff0c96f481fbc66521099f54c03d0`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Repair verified: 2026-08-29 UTC

## What changed

The independent verifier correctly found that the deployed candidate was a
stateless generic Container Apps deployment: it allowed one to three replicas
and had no `/app/data` Azure File mount. That configuration is unsafe for this
single-writer SQLite service.

`npm run deploy` is now the product's explicit deployment entry point. It runs
`scripts/deploy-durable-container.sh`, which builds through the factory helper,
then attaches the product-specific Azure File share, pins
`minReplicas=maxReplicas=1`, deactivates stale revisions, and performs the real
cross-revision private-record check. The README now gives this command.

Regression coverage in `scripts/test-durable-deploy.sh` executes the actual
`npm run deploy` command against the generic helper's unsafe one-to-three
replica fixture. It proves the final patch contains the `checkin-data` Azure
File volume, `/app/data` mount, and one-replica scale before the deployment is
reported successful.

## Deployment evidence

The durable wrapper built the repair code in Azure ACR (`Run ID: ch19x`) and
deployed image
`sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:8edec127fb9f`.
Its final checked revision was `sf-accessible-explanation-9c1a54--0000099`:

- `/health` reports build SHA `8edec127fb9ff0c96f481fbc66521099f54c03d0`.
- The live topology gate reports the product custom domain, one active healthy
  ready/running replica, `minReplicas=1`, `maxReplicas=1`, and the
  `checkin-data` Azure File mount at `/app/data`.
- The share is read/write
  `sf-accessible-explanation-checkin-data` through environment storage
  `aec-accessible-explanati-9c1a54`.
- The real durable workflow created a private check-in, submitted a response,
  saved a teacher review, replaced the production revision, and then received
  24/24 HTTP 200 reads for each student link, review link, and receipt before
  and after replacement. The submission and review fields persisted.

## Verification

Completed from a clean `npm ci` install (86 packages, zero reported
vulnerabilities):

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
cargo fmt --all -- --check
cargo clippy --all-targets --all-features --locked -- -D warnings
cargo build --release --locked
npm run deploy
npm run verify:live-topology
AUDIT_EVIDENCE_PREFIX=repair-10 npm run audit:live
```

- `npm test`: PASS — TypeScript, 5 Vitest tests, 13 Rust tests, and all three
  durable deployment/durability/topology fixtures.
- `npm run build`: PASS — 38.93 kB raw / 12.43 kB gzip JavaScript and 19.30 kB
  raw / 5.16 kB gzip CSS.
- `npm run test:e2e`: PASS — desktop and 390px Chromium app/claim suites;
  keyboard, mobile, demo, offline, student draft, privacy, voice, and review
  paths passed. One transient mobile Chromium process crash was retried by the
  configured fresh-worker retry and the assertion passed.
- `npm run test:all-claims`: PASS — all 25 listed claim commands, including
  the real Azure `verify:live-topology` command.
- Rust format, strict Clippy, and locked release build: PASS.
- The Azure ACR container build passed and is the deployed image above.
- Factory `verify-url.sh` passed live `/` in 545 ms and `/demo` in 536 ms:
  titles, `lang=en`, one H1, main landmark, image alt text, button names, and
  browser console were clean. Artifacts are in `.factory/evidence/repair-10-verify-*`.
- The live Playwright audit exercised seven routes in light and dark themes at
  390px. Axe found zero serious/critical findings, all targets met 44px, 200%
  text had no overflow, route focus/announcements worked, the demo reloaded
  offline, and the full classroom flow made only same-origin requests. See
  `.factory/evidence/repair-10-live-check.json`.
- Lighthouse mobile: performance 100, accessibility 100, best practices 100,
  SEO 100; LCP 1080 ms and CLS 0. The first Chromium tab crashed; the retry
  with `--disable-dev-shm-usage --disable-gpu` completed successfully.
- A live 150-request read-only burst produced 124 HTTP 405 responses and 26
  HTTP 429 responses. The throttled response included `Retry-After: 0` and
  `Cache-Control: private, no-store`.
- Live HTML has the repaired ETag and `/health` identity, plus CSP with
  `frame-ancestors 'none'`, HSTS, `nosniff`, no-referrer policy, and a
  restrictive permissions policy.

## How to operate

```sh
npm ci
npm run deploy
npm run verify:live-topology
```

`npm run deploy` is required for this SQLite-backed Container App. Do not use
the generic container helper directly; it deliberately creates a temporary
one-to-three-replica stateless template.

## Known gaps

None in the product or deployment. The browser process crashes noted above
were transient runner failures; both configured retries and a fresh
Lighthouse run passed.
