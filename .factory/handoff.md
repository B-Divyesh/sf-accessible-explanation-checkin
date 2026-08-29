# Accessible Explanation Check-in — repair 7 handoff

## Result: PASS

- Work order: `accessible-explanation-checkin-repair-7`
- Verifier report: `688dd241b4deba64ca7ab3f0a17eb5d513bfa429`
- Failed candidate: `d47130dbb61411ce9dfb3c832500b361ca9b66cb`
- Functional repair commit: `f2332f6a36b1badc23e95d878a62647b28110dde`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

The one verification-9 release blocker is closed. The student form's local and
offline draft promises now have a dedicated `student-draft-local` entry in
`.factory/claims.json` and exactly one tagged browser regression. No product
behavior or researched scope was removed.

## Root cause and repair

The student form already saved `checkin-draft:<token>` in localStorage, allowed
editing while offline, blocked offline submission, and restored the draft after
reconnect. Those promises appeared in three live status messages, but the
claims inventory only tested offline demo reloads and teacher review-link
storage.

The repair adds:

- the `student-draft-local` claim and its exact sandbox procedure;
- one Playwright test that creates a real check-in, saves all draft fields,
  edits offline, checks the token-scoped key, confirms no submission request,
  reconnects, reloads, and checks restored values;
- the test to both desktop and 390 px release shards;
- inventory-count coverage and student-flow entries in the copy audit.

The final inventory has 25 unique claims, including 19 browser claims. Every
browser claim has a tagged test; `student-draft-local` has one inventory entry
and one tagged test.

## Verification evidence

### Clean install, tests, and build

- `npm ci`: 86 packages installed; 0 vulnerabilities.
- `npm run test:claims -- --grep @claim:student-draft-local`: 2 passed,
  desktop Chromium and 390 px mobile Chromium.
- `npm test`: 5 Vitest tests, 13 Rust tests, and all deployment fixtures passed.
- `npm run test:e2e`: 47 passed and 10 intentional project/fixture skips. One
  Chromium process crash recovered through the configured retry; the affected
  `no-account-needed` test then passed alone without retry.
- `npm run test:all-claims`: all 25 claim commands passed independently,
  including the live deployment-policy check.
- `npm run build`: `dist/` produced; JS 38.93 kB raw / 12.43 kB gzip and CSS
  19.30 kB raw / 5.16 kB gzip.
- `cargo fmt --all -- --check`: passed.
- `cargo clippy --all-targets --all-features -- -D warnings`: passed.
- `cargo build --release --locked`: passed.
- `npm run test:deploy-helper`, `npm run test:container-identity`, and
  `npm run test:runtime-policy`: passed. The release server wrote its durable
  snapshot under an unprivileged UID.

This web-with-backend product is not a package or library, so a package-consumer
installation test does not apply. The ACR build exercised the root multi-stage
Dockerfile successfully.

### Browser, accessibility, privacy, offline, and response policy

- The live audit passed all seven public routes in light and dark at 390 px:
  zero serious/critical Axe findings, zero undersized targets, no horizontal
  overflow at normal or 200% text, correct route focus/announcements, no console
  errors, and a real HTTP 404 page.
- Factory `verify-url.sh` passed `/` and `/demo`: HTTP 200, correct title and
  `lang=en`, one h1, a main landmark, complete image alt text and button names,
  and zero console errors. Browser loads were 556 ms and 538 ms.
- The live desktop classroom flow created, submitted, reviewed, persisted, and
  reloaded a real response. Recorded classroom and demo requests were
  same-origin; no analytics, advertising, model, CDN-font, or third-party
  script request occurred.
- The live 390 px draft flow updated its service worker, kept editing offline,
  stored the exact token-scoped draft, made no offline submission, displayed
  recovery guidance, and restored name, explanation, and confidence after
  reconnect/reload. It produced no console errors.
- Root and service-worker responses revalidate. Hashed assets are immutable.
  Private API and bearer-link responses are `private, no-store` and have no
  ETag. CSP, HSTS, `nosniff`, Permissions Policy, and `no-referrer` are present;
  CSP includes `frame-ancestors 'none'`.
- Product rate limit: 180 concurrent requests returned 120 normal `404`s and
  60 `429`s; all 60 had `Retry-After`. Sociobot license verification: 100
  requests returned 30 normal responses and 70 `429`s; all 70 had
  `Retry-After`.

### Performance and deployment

- Live mobile Lighthouse: 100 performance, 100 accessibility, 100 best
  practices, and 100 SEO; LCP 1.178 s, TBT 73.5 ms, CLS 0, transfer 39,105 bytes.
- The durable deployment wrapper built the container in ACR and deployed repair
  commit `f2332f6a36b1badc23e95d878a62647b28110dde`.
- Deployment revision `sf-accessible-explanation-9c1a54--0000078` reported one
  active/running replica and the read-write Azure File share at `/app/data`.
- The durability gate received 24/24 successful student, review, and receipt
  reads before and after replacement revision `0000078`; submission and saved
  teacher review data survived.
- `/health`, root/service-worker/asset ETags, image tag
  `sf-accessible-explanation-9c1a54:f2332f6a36b1`, and the local/live JavaScript
  SHA-256 `20cd346b11d1d9d05518eecf492ca95ce6f835e2533c781b7cf30be203fd2fa1`
  identified the same build.

## Run and verify

```sh
npm ci
npm run test:all-claims
npm test
npm run test:e2e
npm run build
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo build --release --locked
npm run test:runtime-policy
npm run audit:live
npm run verify:live-topology
```

Deploy only with:

```sh
bash scripts/deploy-durable-container.sh accessible-explanation-checkin /work/repo Dockerfile 8080
```

The final handoff-only commit must also go through that wrapper so live
`/health` and the image tag match final `main`. The wrapper repeats the
cross-revision private-record test before it reports success.

## Known gaps

None. No application, infrastructure, DNS, billing, or package-class deviation
remains. The three pre-existing modified `graphify-out` files were preserved
and excluded from both repair commits.
