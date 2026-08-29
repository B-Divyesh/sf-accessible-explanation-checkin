# Repair 3 handoff — ready

- Work order: `accessible-explanation-checkin-repair-3`
- Repaired from report commit: `1b0395efd1b74712f8cbed0cf8b37a5c5d5eb769`
- Failed candidate: `96472326c1088487c69f739d97e3a3639f3cb4ed`
- Verified: 2026-08-29 UTC
- Live URL: <https://accessible-explanation-checkin.sociobot.in>

## Release blockers repaired

### Cold claim startup

The verifier's 120-second failure was reproduced with a clean target and one
Rust build job. Compilation was still running when Playwright returned
`Timed out waiting 120000ms from config.webServer`.

`frontend/playwright.config.ts` now gives the server 600 seconds and runs
`cargo run --locked`. A clean detached worktree then completed the same
single-job compile in 2 minutes 15 seconds and passed both desktop and 390 px
`demo-isolation` tests. `frontend/src/playwright-config.test.ts` enumerates all
14 browser-backed claim commands and prevents a shorter timeout or unlocked
backend command from returning.

### Durable production topology

The live failure was confirmed before deployment: Container Apps reported
`minReplicas: 1`, `maxReplicas: 3`, no volumes, and no mounts.

The durable deploy wrapper now executes through a configurable factory helper,
applies the one-replica Azure File template, waits until the latest revision is
also ready, deactivates stale revisions, and verifies exactly one active and
running replica before succeeding. Its regression test executes the real
wrapper against mocked fleet and Azure control planes. The test validates the
patch body and proves that an unapplied topology makes deployment fail.

The repaired deployment produced revision
`sf-accessible-explanation-9c1a54--0000035` with one healthy replica,
`minReplicas: 1`, `maxReplicas: 1`, storage
`aec-accessible-explanati-9c1a54`, and an Azure File mount at `/app/data`.
Forty independent reads all returned 200. Forty concurrent submissions returned
the intended 35 × 201 and 5 × 409, with no 404s. After restarting the revision,
the review still returned 200 with all 35 submissions.

## Verification

- `npm ci`: 86 packages, 0 reported vulnerabilities.
- `npm test`: TypeScript passed; 5 Vitest and 11 Rust tests passed; executable
  deployment-policy regression passed.
- `npm run build`: emitted `dist/`; JS 38,782 bytes raw / 12,465 gzip and CSS
  19,296 bytes raw / 5,177 gzip.
- `npm run test:e2e`: 38 passed, 8 intentional mobile skips, 0 failed across
  desktop Chromium and a 390 × 844 mobile viewport.
- `npm run test:all-claims`: all 18 declared commands passed independently.
- `cargo fmt --all -- --check`, locked Clippy with warnings denied, and locked
  release build passed.
- Container-name, build-identity, non-root runtime, and deployment-policy checks
  passed. Docker CLI was unavailable; the production image was instead built
  by Azure Container Registry and deployed successfully.
- Live route crawl: 14 links; seven light and seven dark routes had zero
  serious/critical Axe findings, zero undersized controls, no horizontal
  overflow at 390 px or 200% text, and no console errors.
- Keyboard skip-link, route focus/announcement, and complete classroom keyboard
  workflows passed.
- Demo storage isolation, reset, service-worker update, and offline reload with
  all three samples passed. Browser workflows contacted only the product origin.
- Response policy passed: private routes use `private, no-store`; hashed assets
  use one-year immutable caching; shell and worker revalidate; security headers
  and request IDs are present.
- Live rate limit returned 120 allowed responses and 30 × 429 with
  `Retry-After`; an independent forwarded client remained available.
- Mobile Lighthouse: performance 99, accessibility 100, best practices 100,
  SEO 100; FCP 976 ms, LCP 1,126 ms, CLS 0, TBT 149 ms.

Evidence is in `.factory/evidence/repair-3-release.json`,
`.factory/evidence/repair-3-live-check.json`,
`.factory/evidence/repair-3-lighthouse-mobile.json`, and
`.factory/evidence/repair-3-verify/`.

## Known gaps and operations

There are no known product release blockers. This is still intentionally a
single-writer SQLite service. Every future deployment must use
`scripts/deploy-durable-container.sh`; the generic factory helper alone resets
the app to a stateless 1–3 replica template. The controller may reapply and
verify the same Azure Files mount after deployment.
