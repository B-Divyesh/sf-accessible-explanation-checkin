# Independent verification 5 — FAIL

- Work order: `accessible-explanation-checkin-verify-5`
- Verified: 2026-08-29 UTC
- Candidate: `6c0209c9f783f69e9c6a90fb34aa1ef9765415cf`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>

## Verdict

**FAIL.** The candidate is clear on first read, every declared claim passes in
a detached clean worktree, and the exact local product passes its build,
functional, accessibility, privacy, and runtime gates. The live deployment is
still not reliable for the real teacher → student → review job. It is deployed
without durable storage and permits three replicas. When a second replica
started under fresh QA traffic, exactly half of requests for a newly created
private record returned 404. This is a Critical release blocker.

## Critical defect — live private records split across replicas

Fresh API evidence reproduced the earlier deployment-only failure against the
requested candidate:

1. `POST /api/checkins` returned `201` and separate student/review tokens.
2. Twenty sequential student-link reads returned **10 × 200 and 10 × 404**.
3. Twenty sequential review-link reads returned **10 × 200 and 10 × 404**.
4. Twenty token-dependent invalid submissions, which should reach the record
   and return 400, returned **10 × 400 and 10 × 404**.
5. Every unexpected response said: “That private link is not valid. Check that
   you copied the whole link.”

The Azure control plane established the cause at the same time:

- revision `sf-accessible-explanation-9c1a54--0000046` used image
  `sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:6c0209c9f783`;
- scale was `minReplicas: 1`, `maxReplicas: 3`;
- two replicas were running;
- `volumes` and the app container's `volumeMounts` were both `null`.

The second replica later scaled down, but the unsafe 1–3 setting and absent
mount remained. A single-browser journey can pass while requests happen to
reach one replica; a student opening the link from another connection has no
such guarantee. Evidence:
`verification-5-live-persistence.json` and
`verification-5-live-topology.json`.

Deploy through `scripts/deploy-durable-container.sh` or apply its effective
configuration: exactly one active/running replica, the product Azure File
volume, and `/app/data` mounted in the app container. Then run the repository's
live durability gate through create/read/submit/review and a real revision
restart. Do not release based only on the mocked deployment-policy test.

## Required first-read and demo gate

**PASS.** A cold desktop and 390 px visit answers the required questions on the
first screen:

- What: “Collect student reasoning.”
- Who: teachers who need a low-stakes check-in.
- First action: “Try it with sample data,” followed by “Open a populated
  teacher review; nothing is saved.”

One click opens three realistic watershed explanations and a persistent
“Demo — sample data, nothing is saved” banner with **Reset demo** and **Start
for real**. Demo edits use only the dedicated `demo:` localStorage key, Reset
restores the seed, and the demo makes zero API requests.

## Claims and clean-checkout gates

An independent detached worktree at the exact candidate was clean before
`npm ci`. The first browser claim performed a genuinely cold Rust build in
2m17s and passed inside the configured ten-minute startup budget. All 18
commands in `.factory/claims.json` then passed:

`demo-isolation`, `demo-reset`, `sample-csv-export`, `keyboard-demo`,
`offline-demo`, `no-account-needed`, `voice-retention-control`,
`voice-retention-deletion`, `free-response-limit`, `no-automated-judgment`,
`student-keyboard-flow`, `student-review-workflow`,
`privacy-request-boundary`, `classroom-plus-limits`,
`billing-license-fixture`, `external-checkout`,
`runtime-container-policy`, and `durable-deployment-policy`.

The literal pre-install invocation could not load repository-local Playwright
or Vite because a clean clone has no `node_modules`; the authoritative claim
run above was performed immediately after the documented `npm ci` setup.

| Check | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages; 0 reported vulnerabilities |
| `node scripts/test-all-claims.mjs` | PASS — all 18 commands; cold first claim included |
| `npm test` | PASS — TypeScript, 5 Vitest tests, 11 Rust tests, two policy regressions |
| `npm run build` | PASS — exact production `dist/` produced |
| `npm run test:e2e` | PASS in the candidate workspace — 38 passed, 8 intended skips |
| `npm run test:runtime-policy` | PASS — release server ran under an unprivileged UID and wrote a snapshot |
| deploy-helper / container-identity | PASS |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |

Two subsequent full E2E attempts in the detached worktree each had the
preinstalled Chromium headless-shell process segfault while starting at a
different mobile test; 37 tests passed before each launcher crash, with no
product assertion failure. Both affected tests passed together in an isolated
mobile rerun (2/2). The complete suite had already passed in the exact
candidate workspace. This is recorded as runner instability, not a product
defect. Docker/Podman was unavailable; the non-root release-runtime test and
Docker policy checks passed without an image daemon.

## Functionality and backend boundaries

- A single fresh live browser session completed create → student submission →
  receipt → teacher review → saved tag/note/follow-up → reload. The repeated
  cross-connection test above proves this success is intermittent.
- Local tests accept the exact 120-character title, 1,200-character prompt,
  4,000-character explanation, confidence 1–5, free retention 1–7 days, and
  exactly 35 concurrent free responses. They reject empty/over-limit fields,
  malformed voice, unsupported MIME, unknown tags, and 1,001-character notes
  with actionable errors; recovery, receipt, CSV escaping, voice deletion, and
  retained text pass.
- A release binary started in a temporary directory with only `PORT` supplied.
  It logged each optional configuration source without secrets, created a
  record, shut down gracefully, restarted, and recovered that record.
- A 100-request concurrent `/health` smoke returned **100 × 200** in 444 ms
  (225 requests/second observed).

## Rate limiting

With the live deployment at two replicas, 300 simultaneous requests carrying
one forwarded client IP returned **240 × 404 and 60 × 429**. Every 429 carried
`Retry-After: 0`; a different client remained unblocked. The observed live
allowance was therefore **240**, reflecting the configured 120-request burst
in each independent process. The API does enforce 429 responses, but the live
allowance changes with the same unsafe replica count that breaks persistence.
Evidence: `verification-5-rate-limit.json`.

## Deployment identity, privacy, and response policy

- `/health` returned the full candidate SHA. Root HTML, hashed JS, hashed CSS,
  and the manifest matched the clean production build byte-for-byte. Root ETag
  was the candidate SHA. Evidence: `verification-5-identity.json`.
- Browser request logging across the demo and full classroom flow observed only
  the product origin. The demo made no API requests. There were no cookies,
  analytics, advertising, model calls, third-party scripts, or remote fonts.
- HTTPS redirect, HSTS, CSP with header-only `frame-ancestors 'none'`,
  Permissions Policy, `nosniff`, no-referrer, and request IDs were present.
- Shell and service worker require revalidation; hashed assets are immutable
  for one year; private API and bearer-link navigation use `private, no-store`.
- The production checkout catalog reports $39 USD and the Sociobot endpoint
  returns 303 to a Dodo checkout session. No payment provider is embedded.
- Sign-in is not required, so the Entra tenant requirement is not applicable.

## Accessibility, responsive behavior, PWA, and performance

- Factory `verify-url.sh` passed live `/` and `/demo`: titles, `lang=en`, one
  H1, main landmark, image alternatives, labeled buttons, and zero console
  errors at desktop and 390 px.
- Seven public routes plus the real 404 passed at 390 px in light and dark
  themes with **zero serious/critical Axe findings**, no undersized controls,
  no horizontal overflow, no 200%-text overflow, and no console/page errors.
- Keyboard focus starts on the skip link with a visible 3 px outline; Enter
  focuses main. Demo review controls work by keyboard and announce save state.
  Route changes focus and announce the new H1.
- Reduced motion computed to 0.01 ms transitions/animations, no running
  animation, and automatic scrolling.
- The service worker was activated and updated; cache
  `check-in-shell-v2` served `/demo` offline with all three samples and the
  visible offline notice.
- Production assets: JavaScript 38,782 bytes raw / 12,480 gzip; CSS 19,296
  bytes raw / 5,159 gzip; largest hero 56,604 bytes; no webfonts.
- Fresh live mobile Lighthouse: **100 Performance, 100 Accessibility, 100 Best
  Practices, 100 SEO**; FCP/LCP 1.13 s, TBT 54 ms, CLS 0, 38,698 bytes total.
  Lab Lighthouse did not emit an interaction-derived INP value.

## Handoff

Do not release the current deployment. Product source was not modified during
verification. Apply and verify the repository's durable one-replica topology,
then rerun repeated private-link reads, submission/review persistence, rate
limiting, and the real restart gate before changing this verdict.
