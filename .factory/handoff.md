# Verification 5 handoff — FAIL

- Work order: `accessible-explanation-checkin-verify-5`
- Candidate: `6c0209c9f783f69e9c6a90fb34aa1ef9765415cf`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

## Release decision

**FAIL — do not release.** The exact candidate is live and all clean local
claims/build/runtime gates pass, but the deployed backend is not durable when
it scales. A freshly created student or review link returned 404 on half of
cross-connection requests.

## Critical defect

At the failing observation, active revision
`sf-accessible-explanation-9c1a54--0000046` ran two replicas with
`minReplicas: 1`, `maxReplicas: 3`, no volume, and no `/app/data` mount. A
fresh 201-created record produced:

- student reads: 10 × 200, 10 × 404;
- teacher-review reads: 10 × 200, 10 × 404;
- token-dependent invalid submissions: 10 × expected 400, 10 × 404.

The second replica later scaled down, but the unsafe maximum and absent durable
mount remained. See `.factory/verification-5.md` and the
`verification-5-live-{persistence,topology}.json` evidence files.

## What passed

- Detached clean worktree at the candidate; `npm ci` installed 86 packages
  with zero reported vulnerabilities.
- All 18 `.factory/claims.json` commands passed, including a 2m17s cold first
  browser claim and the non-root/deployment policy claims.
- `npm test`, production build, typecheck, 5 Vitest tests, 11 Rust tests,
  formatting, strict Clippy, release build, runtime policy, container identity,
  and deploy-helper checks passed.
- The complete E2E suite passed once: 38 passed, 8 intended mobile skips. Two
  later detached-worktree runs hit Chromium launcher segfaults at different
  tests; both affected tests passed in an isolated 2/2 rerun.
- First-read and one-click demo gates passed. Live route/Axe, keyboard, 390 px,
  dark mode, 200% text, reduced motion, console, privacy request log, headers,
  caching, PWA update/offline reload, checkout, and link crawl checks passed.
- Live identity matches the candidate byte-for-byte. Lighthouse scored
  100/100/100/100; LCP 1.13 s, TBT 54 ms, CLS 0.
- Rate limit: one client received 240 allowed responses across two processes,
  then 60 × 429; every 429 included `Retry-After: 0`. A different client was
  not limited.

## Required next step

Deploy with `scripts/deploy-durable-container.sh` or equivalent so the live
template has exactly one active/running replica and an Azure File volume mounted
at `/app/data`. Run `scripts/verify-live-durable-workflow.sh` through an actual
revision restart and repeat cross-connection reads before release.

No product source code was changed during verification.
