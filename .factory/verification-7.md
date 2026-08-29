# Independent verification 7 — PASS

- Work order: `accessible-explanation-checkin-verify-7`
- Candidate and live build: `483d53c459b569633ce8682503b76447aee4fe19`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

## Verdict

**PASS.** The deployed application identifies the requested commit in both the root ETag and `/health`. The earlier deployment-only private-link failure was not reproducible: a fresh neutral live teacher → student → receipt → review flow completed, and concurrent re-reads of every private resource were consistent.

## First read and demo

Fresh live `/` plainly says it **collects student reasoning**, says it is for **teachers** needing a low-stakes check-in, and presents **Try it with sample data** with the adjacent result, “Open a populated teacher review; nothing is saved.” This passes the first-read and one-click demo gate.

`/demo` opened a populated three-response watershed review with the persistent “Demo — sample data, nothing is saved” banner, Reset demo, and Start for real. Fresh desktop and 390 px browser contexts observed only product-origin requests (three shell/asset requests), no API call, model, analytics, or ad request, and no console or page error.

## Claims — clean detached checkout

A detached worktree at the exact SHA was clean before installation. `npm ci` installed 86 packages with zero reported vulnerabilities. The cold first Playwright claim compiled the Rust server inside the configured ten-minute startup budget. `npm run test:all-claims` then ran every command declared in `.factory/claims.json` independently and completed all **21/21**:

- Demo: `demo-isolation`, `demo-reset`, `sample-csv-export`, `keyboard-demo`, `offline-demo`.
- No-account/data/retention: `no-account-needed`, `stored-record-shape`, `recent-links-local`, `voice-retention-control`, `voice-retention-deletion`, `free-response-limit`.
- Classroom workflow/privacy: `no-automated-judgment`, `student-keyboard-flow`, `student-review-workflow`, `privacy-request-boundary`.
- Paid/runtime/deployment: `classroom-plus-limits`, `billing-license-fixture`, `refund-license-contract`, `external-checkout`, `runtime-container-policy`, `durable-deployment-policy`.

## Local quality gates

| Check | Result |
| --- | --- |
| `npm test` | PASS — TypeScript, 5 Vitest tests, 12 Rust tests, durable-deploy and live-durability policy checks |
| `npm run build` | PASS — `dist/` produced |
| `npm run test:e2e` | PASS — desktop and 390 px mobile matrix; final Playwright status passed |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |
| `npm run test:container-identity` | PASS — release user is `checkin`, build identity exposed |
| `npm run test:deploy-helper` | PASS |

The exact production build reports 38.57 kB raw / **12.31 kB gzip JavaScript** and 19.30 kB raw / **5.16 kB gzip CSS**, below applicable budgets.

## Functional and backend evidence

On an isolated local database, a blank create form failed native validation and an invalid API payload returned `400` with “Assignment name must be between 1 and 120 characters.” A student who supplied name and confidence but no text or voice got the actionable recovery “Add a text explanation, a voice explanation, or both.” After recovery, a teacher created separate private links; the student submitted a text explanation; the receipt opened; the teacher saved a tag, note, and follow-up flag; reload preserved all three; CSV download was 301 bytes. There were no browser errors.

The live retest used neutral QA text only. It created a check-in, submitted a response, saved a review, then issued 24 concurrent fresh reads of each private student, review, and receipt URL. Results were **24/24 HTTP 200** for each endpoint, each with `Cache-Control: private, no-store`; there were no browser errors. This is fresh evidence that the prior split-replica failure is resolved for the candidate.

`/health` returned `200` and `{"build_sha":"483d53c459b569633ce8682503b76447aee4fe19","status":"ok"}`. The verifier has no authority to force a production revision replacement; the repository's durable-deployment claim and live repeated-read retest passed.

## Accessibility, PWA, privacy, and headers

- Live desktop and 390 px `/demo`: `lang=en`, one `h1`, one `main`, no console or page errors, and zero axe WCAG 2.0/2.1/2.2 AA serious or critical findings.
- Keyboard: first Tab focuses Skip to main content with a visible fired-clay 3 px outline; subsequent header controls remain at least 44 px high. Reduced motion had zero running animations.
- PWA: the deployed `sw.js` controlled `/demo`; `registration.update()` left the current worker active; after first visit the demo reloaded offline with HTTP 200 and its populated heading.
- Live headers include CSP with response-header `frame-ancestors 'none'`, HSTS, `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, and a restrictive Permissions Policy. HTML revalidates and hashed assets are immutable for one year.
- Rate limiting: 140 same-client unknown-token API reads yielded **120 × 404, then 20 × 429**. Every 429 had `Retry-After: 0`; observed allowance is a 120-request burst with the configured one-request-per-second refill.

## Defects by severity

None observed. No release-blocking, high, medium, or low product defect was reproduced in this verification.

## Scope note

This verifier did not initiate an external deployment/revision replacement, which would change production state. The live durability result above covers fresh concurrent private-link reads on the deployed candidate; the repository also has a passing deployment-policy claim for replacement behavior.
