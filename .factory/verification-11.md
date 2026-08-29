# Independent verification 11 — FAIL

- Work order: `accessible-explanation-checkin-verify-11`
- Candidate: `87a80ac54c9bfd7077305b881aac65714cf0c267`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

## Verdict

**FAIL — release blocked (critical).** The application and static assets served
at the live URL identify the requested candidate, but the deployed Container
App permits three replicas. This violates the product's declared durable
SQLite topology, and the final mandatory claim command fails against the live
Azure control plane. A multi-replica SQLite deployment can split private
student/teacher records between independent writers.

## First-read and demo check

**PASS.** A cold browser read says the product does **“Collect student
reasoning”**, says it is **“For teachers who need a low-stakes check-in”**,
and puts **“Try it with sample data”** first, with the immediate outcome
“Open a populated teacher review; nothing is saved.” One click opens `/demo`
with three realistic watershed responses and the persistent banner “Demo —
sample data, nothing is saved,” **Reset demo**, and **Start for real**.

## Release-blocking finding

### Critical — live durable SQLite topology is not enforced

The manifest's final `durable-deployment-policy` command ran the real gate:

```text
$ npm run verify:live-topology
ERROR: live topology check failed: expected minReplicas=maxReplicas=1;
observed minReplicas=1 maxReplicas=3
```

The source contracts use a single durable SQLite writer. Three possible app
replicas make the private-link submission/review workflow unsafe unless they
share and coordinate the exact same durable database, which this release gate
explicitly prohibits. This repeats the deployment-only class of failure
reported in verification 10; fresh control-plane evidence establishes that it
is not closed for this candidate.

Required remediation: deploy through the durable deployment wrapper and prove
the final live revision has `minReplicas: 1`, `maxReplicas: 1`, exactly one
running/ready replica, and the Azure File volume mounted at `/app/data`. Then
rerun `npm run verify:live-topology` and the cross-revision persistence flow.

## Claims gate

`.factory/claims.json` is present with 25 unique, declared claims. From the
clean checkout after `npm ci`, every listed command was invoked sequentially
through the shipped demo entry point (`npm run test:all-claims`). The first 24
claim commands passed (browser demo, local database, billing fixtures,
non-root runtime, and deployment fixtures). The 25th and final command,
`durable-deployment-policy`, failed only when it queried the live topology as
shown above. This alone is a release-blocking failed claim.

The claim list covers demo isolation/reset/disposal, CSV, keyboard and offline
demo, local drafts, account-free creation, stored records, retention and voice
boundaries/deletion, response limits, no automated judgment, student/review
workflow, privacy requests, billing fixtures, runtime policy, and durability.

## Independent browser, privacy, and deployment evidence

- **Candidate/live identity: PASS.** `/health` returned
  `87a80ac54c9bfd7077305b881aac65714cf0c267`; root and hashed asset ETags
  match it. The local and live `index-0K29JA5U.js` SHA-256 both equal
  `20cd346b11d1d9d05518eecf492ca95ce6f835e2533c781b7cf30be203fd2fa1`.
- **Desktop and 390 px demo: PASS.** `/demo` showed three responses and no
  horizontal overflow at 390 px. Console/page error logs were empty.
- **Accessibility: PASS for serious/critical Axe.** Fresh Axe scans on desktop
  and 390 px found zero serious or critical violations. The page has a skip
  link, semantic `main`, one H1, visible named controls, and working keyboard
  claim coverage. The repository does not contain the requested
  `verify-url.sh`; equivalent browser checks were performed directly.
- **Privacy: PASS.** A fresh `/demo` load and interaction requested only
  `https://accessible-explanation-checkin.sociobot.in`; no analytics, model,
  advertising, third-party font, or CDN origin was observed. No sign-in is
  offered, so Entra tenant validation is not applicable.
- **Headers/caching: PASS.** HTML is no-cache/revalidated; the hashed JS is
  immutable. API/private routes are policy-tested as `private, no-store`.
  Live responses include HSTS, `nosniff`, no-referrer, Permissions Policy, and
  an HTTP CSP with `frame-ancestors 'none'`.
- **Rate limiting: PASS.** A single-client 170-read concurrent burst to a
  harmless unknown API token yielded 166 `404`s and four `429`s. Each `429`
  included `Retry-After: 0`. Source configuration is one sustained request per
  second with burst size 120; concurrency means the observed acceptance count
  is not a stable allowance, but enforcement and the required header are real.
- **Offline/PWA: PASS by claim suite.** The claim suite exercised first-visit
  service-worker control then offline demo reload. This is a web-with-backend,
  not a library or CLI.

## Local quality gates

| Check | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages installed; 0 vulnerabilities |
| `npm test` | PASS — TypeScript, 5 Vitest tests, 13 Rust tests, deployment fixtures |
| `npm run build` | PASS — `dist/` produced |
| `npx tsc --noEmit -p frontend/tsconfig.json` | PASS |
| `cargo test` | PASS — 13 tests |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm run test:e2e` | PASS — desktop and 390 px app/claim shards |

The exact production build is 38.93 kB raw / 12.43 kB gzip JavaScript and
19.30 kB raw / 5.16 kB gzip CSS, inside the stated static budgets.

## Defects by severity

1. **Critical:** Production topology has `maxReplicas=3` instead of exactly
   one durable SQLite writer; the mandatory live durability claim fails.
2. **Low (verification harness):** no `verify-url.sh` is present although the
   attached accessibility procedure names it. Equivalent title/lang/main/alt/
   console checks were run in Playwright, but the repository should ship the
   expected reusable script.
