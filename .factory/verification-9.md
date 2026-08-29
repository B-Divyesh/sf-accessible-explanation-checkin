# Independent verification 9 — FAIL

- Work order: `accessible-explanation-checkin-verify-9`
- Candidate: `d47130dbb61411ce9dfb3c832500b361ca9b66cb`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC
- Checkout: `/work/repo`, exact candidate at test start

## Verdict

**FAIL.** The prior deployment-only data-loss defect is repaired. The live
service is now the candidate build, runs one replica, mounts its read-write
Azure File share at `/app/data`, and completed fresh create, submit, review,
voice, concurrency, and persistence checks without intermittent `404`s.

Release remains blocked by the acceptance contract's claims rule. The live
student flow promises that a draft is saved on the device and can be edited
offline, but `.factory/claims.json` has no student-draft claim or test. The
only offline claim is `offline-demo`, which tests the sample demo, not a
student draft. The contract explicitly makes any unlisted claim a failed
review.

## First-read and demo gate

**PASS.** On a cold desktop load the first screen says:

- what it does: **“Collect student reasoning”**;
- who it is for: teachers using a low-stakes text or voice check-in;
- what to click first: **“Try it with sample data”**;
- what that click does: opens a populated teacher review and saves nothing.

The one-click demo contains three realistic watershed explanations and a
persistent “Demo — sample data, nothing is saved” banner with **Reset demo**
and **Start for real**. The cold page returned 200 with no console or page
errors. Evidence: [live-cold-first-read.json](qa-artifacts/live-cold-first-read.json)
and [live demo screenshot](evidence/verification-9-live-demo-mobile.png).

## Claims gate

The first command was intentionally attempted before installation, as ordered;
it could not import the repository's uninstalled `@playwright/test` package.
After the required clean `npm ci` (86 packages, zero audit vulnerabilities),
every exact command in `.factory/claims.json` ran independently and passed.
This bootstrap error is not a failed product assertion, but it is recorded for
full reproducibility.

| Claim | Result |
| --- | --- |
| `demo-isolation` | PASS |
| `demo-reset` | PASS |
| `demo-exit-disposal` | PASS |
| `sample-csv-export` | PASS |
| `keyboard-demo` | PASS |
| `offline-demo` | PASS |
| `no-account-needed` | PASS |
| `stored-record-shape` | PASS |
| `recent-links-local` | PASS |
| `voice-retention-control` | PASS |
| `voice-recording-limits` | PASS |
| `voice-retention-deletion` | PASS |
| `teacher-voice-deletion` | PASS |
| `free-response-limit` | PASS |
| `no-automated-judgment` | PASS |
| `student-keyboard-flow` | PASS |
| `student-review-workflow` | PASS |
| `privacy-request-boundary` | PASS |
| `classroom-plus-limits` | PASS |
| `billing-license-fixture` | PASS |
| `refund-license-contract` | PASS |
| `external-checkout` | PASS |
| `runtime-container-policy` | PASS |
| `durable-deployment-policy` | PASS |

Machine-readable exits are in
[claims-results.json](qa-artifacts/claims-results.json): 24/24 passed.

## Release-blocking finding

### High — student offline-draft promises are absent from the claims inventory

The live code displays these observable promises:

- `frontend/src/main.ts:22`: “Offline. You can keep writing; submission needs a
  connection.”
- `frontend/src/main.ts:149`: “Your writing is saved on this device; reconnect
  and send again.”
- `frontend/src/main.ts:192`: “Draft saved on this device.”

No entry in `.factory/claims.json` covers student draft persistence or offline
editing. `offline-demo` is expressly limited to reloading `/demo`, and
`recent-links-local` covers teacher review links rather than student drafts.
The existing copy audit samples landing and selected revised copy, so its
statement that every promise maps to the inventory misses these student-flow
sentences. This is an unlisted claim and therefore release-blocking under the
supplied claims contract, even though source inspection shows a localStorage
draft and the exercised online recovery flow works.

Required fix: add a dedicated claim and observable browser test, for example
load a real student form, enter fields, go offline, continue editing, verify
the `checkin-draft:<token>` local key, reconnect/reload, and assert the draft is
restored. Alternatively remove the offline/draft-save promises.

No other high, critical, medium, or low product defect was found.

## Local quality gates

| Check | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages, 0 vulnerabilities |
| all 24 claim commands | PASS after install |
| `npm test` | PASS — TypeScript, 5 Vitest, 13 Rust, deployment fixtures |
| `npm run test:e2e` | PASS — 46 passed, 10 intentional project/fixture skips |
| `npm run build` | PASS — `dist/` produced |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm run test:deploy-helper` | PASS |
| `npm run test:container-identity` | PASS |
| `npm run test:runtime-policy` | PASS |

The production frontend is 38.93 kB raw / **12.43 kB gzip JS** and 19.30 kB
raw / **5.16 kB gzip CSS**. The largest loaded mobile hero candidate is 18.66
kB. A direct `docker build` could not be run because this verifier image has no
Docker CLI. The exact release binary, non-root runtime harness, Dockerfile
identity check, deployed image, and live build identity all passed.

## Independent live functional checks

- Blank creation invoked native required-field validation and sent no request.
- A 121-character title, 3-character prompt, retention values 0 and 8, a
  confidence value of 0, and a response without text or voice each returned
  400 with a specific recovery message.
- A 120-character title, 4-character prompt, and one-day retention succeeded.
- An empty student explanation focused an announced error; adding text then
  produced the receipt successfully.
- The normal teacher → student → receipt → teacher review path saved tags,
  note, and follow-up state across reload and exported CSV.
- Voice stopped at 120 seconds; exactly 4 MiB was accepted and 4 MiB + 1 byte
  returned 413. Early deletion preserved text, receipt, and review fields.
- Forty simultaneous submissions produced exactly 35 `201`s and five `409`s;
  the review contained 35 responses.
- Fifty immediate reads of a newly created private review all returned 200.

Evidence: [independent-live-edge-cases.json](qa-artifacts/independent-live-edge-cases.json),
[live-concurrency.json](qa-artifacts/live-concurrency.json), and
[live audit](evidence/verification-9-live-check.json).

## Accessibility, privacy, PWA, headers, and performance

- Factory `verify-url.sh`: PASS — title, `lang=en`, one h1, main landmark, alt
  text, button names, and zero console errors.
- Seven public routes, including the real 404, had zero axe serious/critical
  findings in light and dark themes at 390 px.
- No undersized controls, horizontal overflow, or 200% text overflow was found.
- Keyboard focus begins on the skip link with a visible 3 px fired-clay outline.
  Route changes focus and announce the new h1. Reduced motion had zero running
  animations.
- All recorded demo and classroom requests used only the product origin. No
  analytics, advertising, model, CDN-font, or third-party script request was
  observed. The checkout alone intentionally redirects through Sociobot to
  Dodo.
- The service worker controlled `/demo`, `update()` completed, and the three
  sample responses reloaded offline.
- Root and service-worker responses revalidate. Hashed assets are immutable.
  API and bearer-link responses are `private, no-store` without ETags.
- CSP is delivered as a response header and includes `frame-ancestors 'none'`.
  HSTS, `nosniff`, `Referrer-Policy: no-referrer`, and Permissions Policy are
  present.
- Mobile Lighthouse: **96 performance, 100 accessibility, 100 best practices,
  100 SEO**; LCP 2.403 s, TBT 0 ms, CLS 0, total transfer 38,875 bytes.

Evidence: [verify-url results](verification-artifacts-9/verify-url/verify.json),
[edge/header evidence](qa-artifacts/independent-live-edge-cases.json), and
[Lighthouse summary](qa-artifacts/lighthouse-summary.json).

## Rate limits and live deployment identity

- Product API: 180 same-client requests returned 120 normal responses and 60
  `429`s. Every `429` included `Retry-After: 0`. Observed burst allowance: 120;
  configured refill: one request/second.
- Sociobot license verification: 100 requests returned 30 normal responses and
  70 `429`s. Every `429` included `Retry-After: 4`. Observed allowance: 30.
- `/health` returns the full candidate SHA. Root and hashed asset ETags contain
  that SHA, and byte comparisons of the built JS, CSS, and AVIF against live
  assets are identical.
- Azure revision `sf-accessible-explanation-9c1a54--0000075` runs image
  `...:d47130dbb614`, with one active/ready revision and one running replica.
  `minReplicas=maxReplicas=1`; the expected read-write Azure File share is
  mounted at `/app/data`.

Evidence: [rate limits](qa-artifacts/live-rate-limits.json),
[asset hashes](qa-artifacts/live-local-sha256.txt), and
[live topology](verification-artifacts-9/live-topology.json).

The product has no sign-in, so the Microsoft Entra authority requirement is
not applicable. It is a web backend/PWA, not a library or CLI, so package
consumer installation is not applicable.
