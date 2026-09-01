# Independent verification 17 — PASS

- Work order: `accessible-explanation-checkin-verify-17`
- Candidate commit: `50cf4e550506809ede10fdfe8330df52b5001bbe`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-09-01 UTC

## Verdict

**PASS.** The candidate satisfies the researched brief and factory acceptance
contract. All 25 declared claim commands passed from a clean clone outside the
workspace. The aggregate tests, type checks, lint checks, release build, full
desktop/mobile browser suite, and independent live checks also passed. The
live health identity, frontend bytes, container image tag, and topology match
the candidate. No product defect was found.

## Required first checks

### Cold first read and one-click demo — PASS

A fresh 1440 × 900 browser context opened the live root with no stored state.
The first screen answers all three required questions in plain words:

- What it does: **“Collect student reasoning.”**
- Who it is for: **“For teachers who need a low-stakes check-in…”**
- What to click first: **“Try it with sample data.”** The adjacent text says
  it opens a populated teacher review and saves nothing.

The action opens `/demo` in one click. The demo immediately shows three
realistic watershed explanations and keeps the persistent **Demo — sample
data, nothing is saved** banner, **Reset demo**, and **Start for real**.

Evidence: [first-read desktop](evidence/verification-17-first-read-desktop.png)
and [live mobile demo](evidence/verification-17-live-demo-mobile.png).

### Claims gate — PASS

The supplied repository was cloned to
`/tmp/aec-verification17-clean-22QeDu/repo`, checked out at the exact candidate
SHA, and confirmed clean. `npm ci` installed 86 locked packages and reported
zero vulnerabilities. `npm run test:all-claims` then invoked every command in
`.factory/claims.json` and ended with `PASS: 25 claim commands completed`.

| Claim | Result | Clean-clone evidence |
| --- | --- | --- |
| `demo-isolation` | PASS | Desktop and mobile browser assertions passed |
| `demo-reset` | PASS | Desktop and mobile browser assertions passed |
| `demo-exit-disposal` | PASS | Desktop and mobile browser assertions passed |
| `sample-csv-export` | PASS | CSV header and three sample rows confirmed |
| `keyboard-demo` | PASS | Desktop and mobile keyboard assertions passed |
| `offline-demo` | PASS | Desktop and mobile offline reload passed |
| `student-draft-local` | PASS | Offline draft storage and restore passed |
| `no-account-needed` | PASS | Separate private links created without sign-in |
| `stored-record-shape` | PASS | Exact Rust storage-shape test passed |
| `recent-links-local` | PASS | Desktop state-isolation assertion passed; duplicate mobile project skipped by test design |
| `voice-retention-control` | PASS | Desktop schedule assertion passed; duplicate mobile project skipped by test design |
| `voice-recording-limits` | PASS | 120-second and 4 MiB boundaries passed; duplicate mobile project skipped by test design |
| `voice-retention-deletion` | PASS | Exact Rust scheduled-deletion test passed |
| `teacher-voice-deletion` | PASS | Exact Rust early-deletion test passed |
| `free-response-limit` | PASS | Exactly 35 of 40 concurrent responses accepted |
| `no-automated-judgment` | PASS | API field-shape assertion passed |
| `student-keyboard-flow` | PASS | Keyboard-only receipt flow passed |
| `student-review-workflow` | PASS | Receipt, review persistence, CSV, and print assertions passed |
| `privacy-request-boundary` | PASS | Classroom flow stayed on the product origin |
| `classroom-plus-limits` | PASS | Exact Rust 500-response/365-day fixture passed |
| `billing-license-fixture` | PASS | Active and revoked recorded verdicts passed in both projects |
| `refund-license-contract` | PASS | Refunded-license behavior passed in both projects |
| `external-checkout` | PASS | USD 39 catalog and checkout redirect confirmed |
| `runtime-container-policy` | PASS | Release server ran unprivileged and wrote the durable snapshot |
| `durable-deployment-policy` | PASS | Relocated-clone helper, durability fixtures, and live topology all passed |

The live landing page and README were cross-checked against the manifest. No
unlisted product claim was found.

## Clean-clone build and automated checks

- `npm test`: PASS. TypeScript checking, 5 Vitest tests, 17 Rust tests, and all
  deployment/durability/topology fixtures passed.
- `npm run build`: PASS. `dist/` contains 38.93 kB raw / 12.43 kB gzip
  JavaScript and 19.42 kB raw / 5.19 kB gzip CSS.
- `cargo fmt --all -- --check`: PASS.
- `cargo clippy --all-targets --locked -- -D warnings`: PASS.
- `cargo build --release --locked`: PASS.
- `npm run test:e2e`: PASS. The desktop and 390 px mobile groups completed 49
  assertions; 11 duplicate or project-specific cases were intentionally
  skipped by the suite.
- The clean clone remained unchanged after installation and verification.

The workspace copies of `npm test`, `npm run build`, the Rust checks,
`npm run test:container-identity`, and `npm run test:e2e` also passed.

## Live identity, topology, and persistence — PASS

- `/health` returned build SHA
  `50cf4e550506809ede10fdfe8330df52b5001bbe`.
- Revision: `sf-accessible-explanation-9c1a54--0000137`.
- Image: `sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:50cf4e550506`.
- The product has one active, running, ready replica with min/max `1/1` and a
  healthy `RunningAtMaxScale` state.
- The `data` volume is mounted at `/data` from the product share
  `sf-accessible-explanation-checkin-data`.
- Live JavaScript and CSS SHA-256 values exactly match the locally built files:
  `e72750bade996df55b72ac2fd7bcbb6e2914fc62b2d500ad282c92502dc8e921`
  and `c8311b6ed07628ab1e38f70d44625a21f679bbf5ed63f246b11c0a54b2101ced`.
- A live teacher → student → receipt → review flow retained tags, notes, and
  follow-up state after reload.
- A fresh live concurrency check accepted exactly 35 of 40 submissions,
  returned 409 for the other five, and returned all 35 records on 24/24
  repeated review reads.

## Live normal, boundary, and recovery checks — PASS

- Assignment name: 120 characters accepted; 121 returned 400 with the stated
  1–120 character limit.
- Prompt: 4 characters accepted; 3 returned 400 with the stated 4–1,200 limit.
- Free voice schedule: 1–7 days accepted; 0 and 8 returned 400 with recovery
  guidance.
- A response without text or voice returned 400 and explained what to add.
- Confidence 0 returned 400 and requested a value from 1 to 5.
- Corrected input was accepted and its receipt returned 200.
- An unknown private link returned 404.
- Voice stopped at 120 seconds in the controlled recorder check. Exactly 4 MiB
  was accepted; 4 MiB plus one byte returned 413 with a shorter-recording or
  text alternative.
- Early voice deletion returned success. A later voice read returned 410 while
  the written explanation, receipt, review tags, note, and follow-up remained.
- CSV download, print/save-PDF control, demo reset, and demo exit disposal all
  worked.

Evidence: [live audit JSON](evidence/verification-17-live-check.json).

## Accessibility, keyboard, mobile, and PWA — PASS

- `/`, `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, and the designed
  404 each have `lang=en`, one h1, one main landmark, route-specific title and
  canonical metadata, and working site links.
- Fourteen Axe scans (seven routes in light and dark modes) found zero serious
  or critical issues.
- At 390 × 844, all checked controls were at least 44 px, no route overflowed,
  and 200% text retained the content and navigation.
- The first keyboard stop is the visible “Skip to main content” link with a
  3 px focus outline; activation moves focus to `main`.
- An independent live keyboard-only create and student flow reached the
  receipt. Route changes moved focus to h1 and announced the opened page.
- Reduced-motion mode used automatic scrolling and effectively zero-duration
  transitions.
- The service worker update check found `sw.js` activated with no waiting
  worker and cache `check-in-shell-v2`. `/demo` then reloaded offline and still
  displayed “Watershed reasoning.”
- The URL verifier returned 200 in 591 ms with no console errors, one h1, a
  main landmark, and no missing image alternatives or unlabeled buttons.

Evidence: [URL verifier](evidence/verification-17-verify-url/verify.json),
[focus screenshot](evidence/verification-17-focus.png), and
[mobile 404](evidence/verification-17-live-404-mobile.png).

## Privacy, headers, caching, and request allowances — PASS

- The live demo made zero API requests and changed only its `demo:` browser
  namespace. Reset restored the seed; leaving removed every `demo:` key.
- The real classroom workflow contacted only
  `https://accessible-explanation-checkin.sociobot.in`. No analytics,
  advertising, model, external font, or external script request was observed.
- The checkout leaves the product only after user activation. The public
  catalog reported USD 39 once, and checkout returned 303 to the hosted Dodo
  session.
- HTML, `/health`, and `sw.js` use revalidation caching. Hashed assets use
  `public, max-age=31536000, immutable`. Private routes and API responses use
  `private, no-store` without an ETag.
- Responses include CSP with `frame-ancestors 'none'`, one-year HSTS,
  `nosniff`, `Referrer-Policy: no-referrer`, and Permissions Policy.
- A fresh product-API client received 120 ordinary responses in a concurrent
  180-request check, then 60 responses with status 429. Every 429 carried
  `Retry-After: 0`. A second client remained independent. The configured
  allowance is a burst of 120 with one request per second refill.
- The product-license API returned 30 ordinary responses in a concurrent
  60-request check, then 30 responses with status 429. Every 429 carried
  `Retry-After: 4`. The observed burst allowance is 30.
- The product has no sign-in flow, so the Entra authority check is not
  applicable.

## Performance — PASS

- Two fresh mobile Lighthouse runs scored Performance 95 and 96,
  Accessibility 100, Best Practices 100, and SEO 100.
- The repeat run measured FCP 0.9 s, LCP 1.1 s, total blocking time 240 ms,
  CLS 0, and 38 KiB transferred.
- A 390 px interaction check with 4× CPU throttling measured a maximum event
  duration of 40 ms across theme and in-page navigation actions.
- JavaScript is 12.43 kB gzip, CSS is 5.19 kB gzip, and the largest hero AVIF
  is 56.6 kB. All are within the factory bundle budgets.

Evidence: [Lighthouse repeat](evidence/verification-17-lighthouse-mobile-repeat.json).

## Defects by severity

No critical, high, medium, or low product defects were found.

## Tooling note

This verifier image does not provide a Docker CLI. The repository's locked
release build, container-identity check, non-root runtime claim, durable-write
claim, and exact live image/build identity supplied the container evidence.
