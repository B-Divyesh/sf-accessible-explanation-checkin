# Verification 3 handoff — FAIL

Candidate `96472326c1088487c69f739d97e3a3639f3cb4ed` was independently tested on
2026-08-29 against <https://accessible-explanation-checkin.sociobot.in>.

## Result

**FAIL — do not release.** The live backend is running three replicas without
the declared Azure File volume. A newly created private link returned 404 on
two of every three requests (20/30 sequential reads; exact repeating
`404, 404, 200` pattern). Forty concurrent reads and submissions independently
returned 27 × 404 and 13 successes. Azure reports `replicas: 3`,
`maxReplicas: 3`, `volumes: null`, and no app volume mounts.

The first declared claim command also failed from the installed clean checkout
because Playwright's 120-second web-server timeout expired during the cold Rust
compile. It passed after compilation, and a warm aggregate run completed all
18 claims, but the acceptance contract makes the original claim failure
release-blocking.

## What passed

- First-read and one-click sample-demo gate.
- `npm test`, `npm run build`, and the full Playwright suite (38 passed,
  8 intentional skips).
- All 18 claim commands after warm compilation.
- Rust formatting, Clippy with warnings denied, locked release build, container
  identity, non-root runtime, and source deployment-policy checks.
- Local default startup with only `PORT`, restart persistence, invalid-input
  recovery, exact local 35-response concurrency limit, and CSV safety.
- Live build identity and byte-for-byte frontend assets.
- Live 120-request per-client burst limit: 30/150 requests returned 429 and all
  included `Retry-After`; another client remained available.
- Seven-route light/dark Axe scan with zero serious/critical findings, 390 px
  layout, keyboard focus, reduced motion, 200% text, offline reload, request
  privacy, security/caching headers, and console checks.
- Mobile Lighthouse: performance 90, accessibility 100, best practices 100,
  SEO 100; LCP 1.149 s and CLS 0.

## Required next steps

1. Apply and verify the live one-replica plus `/app/data` Azure File settings.
2. Confirm create/read/submit/review behavior across independent connections
   and after a production restart.
3. Make the claims runner tolerate or prebuild for a clean cold Rust compile.
4. Re-run every `.factory/claims.json` command from a new clean checkout.

Full evidence and commands are in `.factory/verification-3.md`; compact machine
evidence is under `.factory/evidence/verification-3-*.json`. No product code was
changed during verification.
