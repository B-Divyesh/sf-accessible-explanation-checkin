# Verify student explanation check-ins — verification 21

- Work order: `accessible-explanation-checkin-verify-21`
- Checked: 2026-09-05 UTC
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Implementation candidate: `8f2956bf5bafed7b9d0b27b53b92bf9cf3abd6bd`
- Repair documentation: `bd999e723236f2583b9a7e2fb239df3a798cc898`
- Checkout head: `633f153e48e82764d412329b7089ae88ae062db6`
- Finding count: **1**
- Untested claim count: **0**

## Verdict

**FAIL — one critical deployment-identity finding blocks release.**

The user-facing product works in the checked desktop, phone, keyboard,
offline, invalid-input, restart, and deletion paths. However, the final
declared claim command fails. The live immutable image and `/health` identify
the later Graphify-only checkout head, not the implementation candidate.

## First screen

A fresh 390 × 844 browser and a fresh 1280 × 900 browser showed these items
before scrolling:

- Job: **Collect student reasoning**.
- Audience: teachers who need a low-stakes text or voice check-in.
- First action: **Try it with sample data**.
- Stated result: **Open a populated teacher review; nothing is saved.**

The title names the job, and the page uses plain task headings. The first
screen also states the account, voice-retention, and 35-response facts.

Evidence: [phone first screen](evidence/verification-21-live-home-mobile.png)
and [desktop first screen](evidence/verification-21-live-home-desktop.png).

## Critical finding

### Live image identity does not match the implementation candidate

The clean candidate resolver returns `8f2956bf…`. Its ACR tag resolves to
`sha256:ee3d2502…`. The live Container App revision is now `0000151` and runs
`sha256:b96f54e3…`. Live `/health` reports `633f153…`.

The exact final command in the `durable-deployment-policy` claim fails:

```text
ERROR: live topology check failed: image
sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54@sha256:b96f54e3…
does not match candidate tag 8f2956bf5baf
```

This is a recurrence of verification 20's release blocker after repair 17.
The repair record identifies revision `0000150`, digest `ee3d2502…`, and build
`8f2956bf…`; independent QA found a later revision. The live JS, CSS, and hero
asset hashes still exactly match a clean build of `8f2956bf…`, so no
user-facing product-code difference was found. The defect is the failed
immutable image/build-identity guarantee, not the expected HTTP 404 or a
functional data-loss result.

Evidence: [topology result](evidence/verification-21-topology.json).

Required disposition: restore the live revision to the candidate image digest
and ensure later report or Graphify commits cannot publish a replacement image.
Then rerun the complete claim manifest from a clean checkout.

## Declared claims

The manifest has 27 unique entries. I ran `npm run test:all-claims` from a
clean detached checkout after `npm ci`. Every entry was reached. The first 26
passed; the final claim's three local fixture commands passed and its live
topology command failed. No claim is untested.

| Claim | Result |
| --- | --- |
| `demo-isolation` | PASS |
| `demo-reset` | PASS |
| `demo-exit-disposal` | PASS |
| `sample-csv-export` | PASS |
| `keyboard-demo` | PASS |
| `offline-demo` | PASS |
| `student-draft-local` | PASS |
| `no-account-needed` | PASS |
| `stored-record-shape` | PASS |
| `recent-links-local` | PASS |
| `prompt-character-limit` | PASS |
| `voice-retention-control` | PASS |
| `voice-recording-limits` | PASS |
| `voice-retention-deletion` | PASS |
| `teacher-voice-deletion` | PASS |
| `teacher-checkin-deletion` | PASS |
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
| `durable-deployment-policy` | **FAIL** — live digest mismatch |

The landing page, application routes, README, demo notes, privacy page, terms,
and copy audit were cross-checked against the manifest. No unlisted public
claim was found.

## Clean-checkout results

The checkout was detached at the implementation candidate and remained clean.
Tools were Node 22.23.2, npm 10.9.8, Rust 1.98.0, and Cargo 1.98.0.

| Command | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages, zero audit vulnerabilities |
| `npm run test:all-claims` | **FAIL only at the final live topology assertion** |
| `npm test` | PASS — TypeScript, 5 Vitest, 18 Rust, and deployment fixtures |
| `npm run build` | PASS — `dist/` produced |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm run test:container-identity` | PASS |
| `npm run test:runtime-policy` | PASS under an unprivileged UID |
| `npm run test:e2e` | PASS — 52 passed, 12 intentional device/project skips |

The production bundle is 12.76 KB gzip JavaScript and 5.20 KB gzip CSS.

## Live user and backend checks

- One click opened three realistic watershed explanations in a populated
  teacher review. The persistent sample label, reset, sample CSV, and start-real
  disposal worked. Demo edits made no API request.
- A real teacher → student → receipt → teacher review flow passed. Saved tags,
  note, and follow-up state survived reload. The audit deleted its record.
- Whole-check-in deletion returned 404 for the student, review, and receipt
  links. This 404 is the promised deletion result.
- A 1,201-character prompt showed the server recovery message and focused the
  alert. A 1,200-character prompt created links. An empty student explanation
  showed the required-field recovery message. The boundary record was deleted.
- Voice stopped at 120 seconds, accepted 4,194,304 bytes, rejected 4,194,305
  bytes, and could be deleted while text, receipt, and review remained.
- An actual restart replaced the sole replica. Ten student, review, and receipt
  reads passed afterward, including saved teacher review state. The test record
  was deleted. See [restart evidence](evidence/verification-21-restart-persistence.json).
- The live topology otherwise has one healthy, ready replica, min/max 1/1, and
  its product-specific Azure Files volume mounted at `/data`.
- A 150-request same-client burst returned 120 expected 404 responses and 30
  HTTP 429 responses. Every 429 had `Retry-After`. See
  [rate-limit evidence](evidence/verification-21-rate-limit.json).
- The live $39 checkout request returned HTTP 303 to Dodo's hosted checkout.
  No payment was attempted.

## Accessibility, routes, privacy, and performance

- `/`, `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, and the designed
  missing page have route-specific titles, one h1, one main landmark, correct
  canonical metadata, and consistent navigation. The missing page deliberately
  returns HTTP 404 and offers a route home.
- Axe found zero serious or critical issues on all seven routes in light and
  dark themes. Phone controls met 44 px targets, 200% text had no horizontal
  overflow, and desktop/mobile pages had no unexpected console errors.
- Keyboard checks passed the skip link, form, confidence controls, review
  actions, route focus, and polite route announcements.
- Reduced motion produced automatic scrolling and 0.01 ms transition/animation
  durations. There is no loop or flash.
- The service worker was active with no waiting update. The populated demo
  reloaded offline from `check-in-shell-v2`.
- The demo and real classroom flow contacted only this product origin. No
  analytics, advertising, model, external font, or external script request was
  observed. Security headers include CSP, HSTS, Permissions Policy, nosniff,
  and no-referrer.
- Factory URL checks passed home and demo with no console error. See
  [home check](evidence/verification-21-verify-home/verify.json) and
  [demo check](evidence/verification-21-verify-demo/verify.json).
- Mobile Lighthouse scored Performance 99, Accessibility 100, Best Practices
  100, and SEO 100. LCP was 1.181 seconds, total blocking time 123 ms, CLS 0,
  and total transfer 39,445 bytes. See
  [Lighthouse evidence](evidence/verification-21-lighthouse-mobile.json).

The product has no sign-in flow, so tenant isolation between accounts is not
applicable; private random links are its access boundary. It is not a CLI,
library, or desktop product. The brief rejects automated misconduct inference,
so adding an AI judgment step would not be useful missed leverage.

## Earlier finding disposition

All verification 1–20, review 1–8, polish 1–8, and repair 17 reports were
inspected, including minor copy and harness findings.

| Earlier findings | Current evidence |
| --- | --- |
| Split or non-durable SQLite replicas; unsafe scaling | Closed: one mounted replica and actual restart persistence passed. |
| Quota race and numeric prompt/voice/retention limits | Closed: concurrency, exact boundaries, cleanup, and local claim tests passed. |
| Root runtime, missing hardening, and cache policy | Closed: non-root runtime tests and live headers/cache behavior passed. |
| Pilot billing, broken checkout, refund, and license states | Closed: production checkout redirect plus recorded valid/revoked/refunded tests passed. |
| Demo absence, isolation, reset, or disposal | Closed in fresh live phone/desktop contexts with zero demo API writes. |
| Missing claims, including offline draft and deletion promises | Closed: 27-entry inventory is complete; all except the live identity claim pass. |
| Route focus, metadata, 404, Privacy navigation, link labels | Closed across every live public route. |
| Small targets, 200% text overflow, contrast, keyboard, reduced motion | Closed by E2E, live layout checks, and Axe in both themes. |
| Copy length, jargon, slogan headings, “judgement,” and README wording | Closed in current rendered copy and `.factory/copy-audit.md`. |
| Lockfile, Playwright pin, clean-path harness, and E2E reliability | Closed in the detached checkout and complete browser matrix. |
| Candidate not deployed / image identity in verifications 18 and 20 and review F-6-1 | **Reopened:** revision `0000151` does not identify candidate `8f2956bf…`. |

## Counts

- Critical findings: **1**
- High findings: **0**
- Medium findings: **0**
- Low findings: **0**
- Total findings: **1**
- Untested claims: **0**

**Final verdict: FAIL.**
