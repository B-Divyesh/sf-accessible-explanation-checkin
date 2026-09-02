# Independent verification 19 — PASS

- Work order: `accessible-explanation-checkin-verify-19`
- Candidate commit: `b6ea22ce6875778503e053da80d0b1279bdc02a9`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-09-02 UTC

## Verdict

**PASS.** The live deployment matches the candidate and satisfies the
researched brief and factory acceptance contract. All 26 declared claim
commands passed from a clean detached clone. Local builds, tests, strict Rust
checks, desktop/mobile browser suites, and fresh live checks passed. The prior
deployment-only identity failure is resolved. No product defect was found.

## Required first checks

### Cold first read and one-click demo — PASS

A fresh 1440 × 1000 browser context opened the live root without stored state
or service-worker mediation. The first screen answers all three questions in
plain words:

- What it does: **“Collect student reasoning.”**
- Who it serves: **“For teachers who need a low-stakes check-in…”**
- What to click: **“Try it with sample data.”** Adjacent copy says it opens a
  populated teacher review and saves nothing.

One click opened `/demo`. It immediately showed a realistic watershed prompt
and three student explanations, plus the persistent **Demo — sample data,
nothing is saved** banner, **Reset demo**, and **Start for real**.

Evidence: [cold desktop](verification-artifacts-19/first-read-desktop.png) and
[one-click demo](verification-artifacts-19/demo-after-one-click-desktop.png).

### Claims gate — PASS

The supplied workspace was at a later verifier commit and contained unrelated
Graphify modifications, so it was not used for candidate execution. I cloned
the same repository to `/tmp/aec-qa-b6-SuFPEr`, checked out the exact candidate
SHA detached, confirmed it clean, and ran `npm ci`. It installed 86 locked
packages with zero reported vulnerabilities. `npm run test:all-claims` then
invoked every command from `.factory/claims.json` separately and ended with
`PASS: 26 claim commands completed`.

| Claim | Result | Evidence |
| --- | --- | --- |
| `demo-isolation` | PASS | Populated review; only the `demo:` namespace changed |
| `demo-reset` | PASS | Shipped sample restored |
| `demo-exit-disposal` | PASS | All demo keys discarded |
| `sample-csv-export` | PASS | Header plus three sample rows |
| `keyboard-demo` | PASS | Skip link and review action operated by keyboard |
| `offline-demo` | PASS | Fresh-context offline reload succeeded |
| `student-draft-local` | PASS | Offline draft restored after reconnect |
| `no-account-needed` | PASS | Separate student/review links without sign-in |
| `stored-record-shape` | PASS | Exact Rust storage-shape test |
| `recent-links-local` | PASS | Browser namespace isolation confirmed |
| `voice-retention-control` | PASS | Free 1/3/7-day choices confirmed |
| `voice-recording-limits` | PASS | 120 seconds and 4 MiB boundaries confirmed |
| `voice-retention-deletion` | PASS | Scheduled deletion kept text |
| `teacher-voice-deletion` | PASS | Early deletion kept text and review |
| `teacher-checkin-deletion` | PASS | Check-in, responses, receipts, and voice removed |
| `free-response-limit` | PASS | Exactly 35 of 40 concurrent submissions accepted |
| `no-automated-judgment` | PASS | No automated result fields returned |
| `student-keyboard-flow` | PASS | Required fields submitted keyboard-only |
| `student-review-workflow` | PASS | Receipt, saved review, CSV, and print controls |
| `privacy-request-boundary` | PASS | Classroom flow stayed on product origin |
| `classroom-plus-limits` | PASS | Recorded valid-license server fixture |
| `billing-license-fixture` | PASS | Active then revoked fixture relocked controls |
| `refund-license-contract` | PASS | Refunded fixture retained free experience |
| `external-checkout` | PASS | USD 39 catalog and Dodo redirect |
| `runtime-container-policy` | PASS | Unprivileged release runtime wrote durable snapshot |
| `durable-deployment-policy` | PASS | Deployment fixtures and live topology/identity passed |

Some browser claims intentionally skip their duplicate mobile project. The
dedicated mobile suite below exercises all applicable mobile assertions. The
landing page and README were cross-checked against the manifest; no unlisted
claim-like promise was found.

## Clean-clone build and automated checks

- `npm test`: PASS — TypeScript, 5 Vitest tests, 18 Rust tests, and deployment,
  durability, and topology fixtures.
- `npm run build`: PASS — generated `dist/`.
- Production bundle: JavaScript 40.34 kB raw / 12.76 kB gzip; CSS 19.47 kB raw
  / 5.20 kB gzip; largest hero AVIF 56.60 kB.
- `cargo fmt --all -- --check`: PASS.
- `cargo clippy --all-targets --locked -- -D warnings`: PASS.
- `cargo build --release --locked`: PASS.
- `npm run test:container-identity`: PASS.
- `npm run test:deploy-helper`: PASS.
- `npm run test:e2e`: PASS — 51 passed and 11 deliberate
  duplicate/project-specific skips across desktop and 390 px projects.

A Docker CLI was unavailable. The locked release build, non-root runtime
claim, Dockerfile identity test, and exact running-image identity supplied the
container evidence.

## Live identity, topology, and persistence — PASS

- `/health` reports build SHA
  `b6ea22ce6875778503e053da80d0b1279bdc02a9`.
- The image is
  `sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:b6ea22ce6875`.
- Fresh local/live SHA-256 values match byte-for-byte: JavaScript
  `44bec312b504c32af34b50a615f4aa221bac1ffca17e0440b3daa32d230e4b0d`;
  CSS `2a20014dbe9a731ac94a02d87848887b57286ac59ca867b3d273f6f2681032b6`.
- A fresh durability run replaced revision `0000142` with `0000143`. It kept
  one active, running replica with min/max `1/1`, mounted the product Azure
  Files share at `/data`, and preserved the submitted explanation plus saved
  teacher review.
- Student, review, and receipt links each returned 200 on 24/24 reads before
  and 24/24 reads after the replacement revision.
- The final revision is healthy, ready, `RunningAtMaxScale`, and still reports
  the candidate SHA.

This directly closes the deployment-only concern reported in verification 18
and rechecks the multi-replica data-loss failure from verification 15.

## Live functional, boundary, and recovery checks — PASS

- Teacher creation returned distinct private student/review links; student
  text and confidence reached a receipt and teacher review; tags, note, and
  follow-up state survived reload; CSV downloaded correctly.
- Teacher deletion removed the check-in, submissions, receipt links, and voice
  data. The product audit observed 404 for all three private API links.
- A 120-character assignment name was accepted by the claim suite; 121
  returned 400 with the documented limit. A four-character prompt was
  accepted; three returned 400.
- Free voice schedules accept one through seven days; zero and eight returned
  400 with recovery guidance.
- Missing text/voice, confidence zero, a 4,001-character explanation, an
  unsupported voice type, a 1,001-character teacher note, and an unknown tag
  each returned a specific 400 response. Corrected values were accepted.
- Exactly 35 of 40 simultaneous live submissions returned 201; five returned
  409, and the review contained exactly 35 records.
- Controlled live voice checks stopped at 120 seconds, accepted exactly 4 MiB,
  rejected 4 MiB plus one byte with 413, and retained written/review data after
  early voice deletion.
- The public checkout reported USD 39 and returned a user-initiated 303 to the
  hosted Dodo checkout. No payment was attempted.

## Accessibility, keyboard, mobile, and PWA — PASS

- `/`, `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, and the designed
  404 each have `lang=en`, one `h1`, one `main`, route-specific metadata, and
  working navigation.
- Fourteen fresh Axe route/theme scans found zero serious or critical issues.
- The first keyboard stop is the skip link with a 3 px solid focus outline;
  Enter moves focus to `main`. The keyboard-only student claim passed.
- At 390 × 844, audited controls meet the 44 px target rule and no public
  route has horizontal overflow. All seven public routes also remained within
  390 px after the root font size doubled to 32 px.
- Reduced-motion mode uses `scroll-behavior: auto` and effectively zero-duration
  transitions. Light and dark treatments were both checked.
- `verify-url.sh` passed live home and demo with correct title, language, h1,
  main, image alternatives, labeled buttons, and zero console errors.
- The active service worker had no waiting update, cache
  `check-in-shell-v2`, and reloaded the populated demo offline.

Evidence: [URL verifier](verification-artifacts-19/verify-home/verify.json),
[mobile reduced motion](verification-artifacts-19/demo-mobile-reduced.png),
[dark mobile home](verification-artifacts-19/home-mobile-dark.png), and
[keyboard focus](verification-artifacts-19/keyboard-focus.png).

## Privacy, headers, caching, and request allowances — PASS

- A cold load requested only HTML, the product JS/CSS, and its self-hosted
  image. A separate create → student → receipt → review browser flow made 19
  requests, all to the product origin. There were no analytics, advertising,
  model, external-font, or external-script requests and no console errors.
- Demo edits remain in the `demo:` namespace, reset to the seed, and are
  discarded on exit. Successful student submission clears its local draft.
- HTML, `/health`, and `sw.js` revalidate. Hashed assets use
  `public, max-age=31536000, immutable`. Private pages and API responses use
  `private, no-store` without an ETag.
- Responses include CSP with `frame-ancestors 'none'`, one-year HSTS,
  `nosniff`, `Referrer-Policy: no-referrer`, and Permissions Policy.
- Product API allowance: a fresh same-client 150-request burst returned 120
  ordinary 404 responses followed by 30 HTTP 429 responses. Every 429 included
  `Retry-After: 0`. Source policy is burst 120 with one request/second refill.
- Product-license API allowance: a fresh same-client 60-request burst returned
  30 normal invalid-license responses and 30 HTTP 429 responses. Every 429
  included `Retry-After: 4`.
- The product has no sign-in flow, so Entra tenant validation is not applicable.

## Performance — PASS

Fresh mobile Lighthouse scored Performance 100, Accessibility 100, Best
Practices 100, and SEO 100. It measured FCP 1.0 s, LCP 1.2 s, total blocking
time 80 ms, CLS 0, and 39 KiB transferred. All configured asset and load
budgets pass.

Evidence: [Lighthouse JSON](verification-artifacts-19/lighthouse-mobile.json).

## Defects by severity

No critical, high, medium, or low product defects were found.

## Reproduction

```sh
npm ci
npm run test:all-claims
npm test
npm run build
cargo fmt --all -- --check
cargo clippy --all-targets --locked -- -D warnings
cargo build --release --locked
npm run test:container-identity
npm run test:e2e
npm run audit:live
npm run verify:live-topology
```
