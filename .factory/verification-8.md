# Independent verification 8 — FAIL

- Work order: `accessible-explanation-checkin-verify-8`
- Candidate: `33cc77d99a11d16010227138259a90d5cd24c073`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC
- Clean checkout: detached worktree at the exact candidate SHA

## Verdict

**FAIL.** The candidate code passes its clean-checkout claims, tests, build,
accessibility, privacy, PWA, rate-limit, and performance checks. The deployed
backend does not satisfy its storage topology contract, however. It is running
two ephemeral SQLite replicas with scaling allowed to three and no durable
volume. A check-in created during this review returned intermittent `404`
responses on every private resource. This breaks the core teacher-to-student
workflow and is release-blocking.

The live artifact itself matches the candidate: `/health`, the shell ETag, and
the deployed image tag all identify `33cc77d99a11d16010227138259a90d5cd24c073`.
This is a deployment-configuration failure, not a stale-build result.

## First-read and demo gate

**PASS.** A cold desktop visit shows the job-first heading **“Collect student
reasoning”**, says it is for teachers using a low-stakes text or voice
check-in, and puts **“Try it with sample data”** on the first screen. The
adjacent sentence says that it opens a populated teacher review and saves
nothing. The one-click `/demo` contained three realistic watershed responses,
the persistent demo banner, Reset demo, and Start for real.

Cold-page requests were only the product document, hashed JS/CSS, and its
self-hosted classroom image. There were no console or page errors. Screenshots
are in [verification-artifacts-8](verification-artifacts-8/).

## Required claim tests

`npm ci` in a detached clean worktree installed 86 packages with zero reported
vulnerabilities. `npm run test:all-claims` executed every command in
`.factory/claims.json` separately and ended with `PASS: 24 claim commands
completed.`

| Claim | Result | Observable evidence |
| --- | --- | --- |
| `demo-isolation` | PASS | Populated review; demo-only storage; no API write |
| `demo-reset` | PASS | Shipped sample note restored |
| `demo-exit-disposal` | PASS | All `demo:` keys cleared and seed restored |
| `sample-csv-export` | PASS | Header plus three sample rows downloaded |
| `keyboard-demo` | PASS | Skip link and review action operated by keyboard |
| `offline-demo` | PASS | Service-worker-controlled demo reloaded offline |
| `no-account-needed` | PASS | Distinct student/review links created without sign-in |
| `stored-record-shape` | PASS | SQLite record and voice metadata asserted |
| `recent-links-local` | PASS | Recent review link stayed in one browser |
| `voice-retention-control` | PASS | Free 1/3/7-day selection and notice asserted |
| `voice-recording-limits` | PASS | 120-second stop; 4 MiB accepted; +1 byte rejected |
| `voice-retention-deletion` | PASS | Expired voice removed while text remained |
| `teacher-voice-deletion` | PASS | Early audio deletion preserved text and review |
| `free-response-limit` | PASS | Exactly 35 of 40 concurrent submissions accepted |
| `no-automated-judgment` | PASS | No grade, AI-use, identity, or misconduct result fields |
| `student-keyboard-flow` | PASS | Required student flow completed by keyboard |
| `student-review-workflow` | PASS | Submission, review, receipt, CSV, and print controls exercised |
| `privacy-request-boundary` | PASS | Demo/classroom flow stayed on product origin |
| `classroom-plus-limits` | PASS | Recorded valid license allowed 500 responses/365 days |
| `billing-license-fixture` | PASS | Recorded revoked verdict relocked paid controls |
| `refund-license-contract` | PASS | Recorded refund verdict relocked paid controls |
| `external-checkout` | PASS | USD 39 catalog and Dodo checkout redirect verified |
| `runtime-container-policy` | PASS | Release server ran unprivileged and wrote its snapshot |
| `durable-deployment-policy` | PASS in mocked sandbox; **false live** | Wrapper fixtures pass, but live topology and private-link probes fail below |

The landing page and README claims map to the inventory. The live falsehood is
the production durability claim: its test validates the deployment wrapper
against mocked controls, so it does not detect a deployment that bypasses that
wrapper.

## Clean-checkout quality gates

| Check | Result |
| --- | --- |
| `npm test` | PASS — TypeScript, 5 Vitest tests, 13 Rust tests, two deployment fixtures |
| `npm run build` | PASS — `dist/` produced |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |
| `npm run test:container-identity` | PASS |
| `npm run test:deploy-helper` | PASS |
| `npm run test:e2e` | PASS — 46 passed, 10 intentional device/fixture skips |

The production frontend is 38.93 kB raw / **12.43 kB gzip JS** and 19.30 kB
raw / **5.16 kB gzip CSS**. The release backend was built by the runtime claim.
The container image could not be rebuilt directly because this verifier image
does not contain Docker; Dockerfile policy and the release runtime were covered
by the passing identity and non-root tests.

## Independent functional checks

The live demo loaded three responses without API calls. A blank create form
showed native required-field validation. A 121-character assignment name
returned `400` with “Assignment name must be between 1 and 120 characters.” A
student submission without text or voice showed “Add a text explanation, a
voice explanation, or both.” Adding text recovered successfully. The teacher
then saved Uses evidence, a private note, and follow-up; all persisted on a
reload that reached the same replica. The downloaded CSV was 345 bytes, had
the header and one data row, and contained both the student and teacher note.

All browser requests in the demo and this real workflow used the product
origin. No analytics, advertising, model, or font request appeared. The
checkout is routed through the Sociobot billing endpoint. The product requires
no sign-in, so the Entra authority requirement is not applicable.

## Release-blocking live backend evidence

Azure read-only control-plane inspection showed:

- revision `sf-accessible-explanation-9c1a54--0000065` is healthy and ready;
- image `sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:33cc77d99a11`;
- `minReplicas = 1`, `maxReplicas = 3`;
- two replicas are currently Running;
- `volumes = null` and `volumeMounts = null`;
- the only injected environment variable is `PORT=8080`.

The image defaults point SQLite at `/tmp/checkins.db` and its snapshot at
`/app/data`, but `/app/data` is not mounted. Each replica therefore owns a
different ephemeral database.

A new check-in created through the live UI was read 36 times per resource over
fresh concurrent connections:

| Private resource | HTTP 200 | HTTP 404 |
| --- | ---: | ---: |
| Student check-in | 17 | 19 |
| Teacher review | 19 | 17 |
| Student receipt | 18 | 18 |

These are not synthetic unknown-token probes. They are three private resources
from one check-in created and completed during this verification. The near
50/50 split corresponds to the two live replicas and freshly reproduces the
previous deployment-only failure.

`/health` returned `200` and
`{"build_sha":"33cc77d99a11d16010227138259a90d5cd24c073","status":"ok"}`.
The repository's deployment wrapper is designed to mount Azure Files and pin
one replica, but the current revision was not deployed with that topology.

## Accessibility, privacy, PWA, headers, and performance

- Factory `verify-url.sh`: PASS — title, `lang=en`, one h1, main landmark, alt
  text, labels, and zero console errors.
- Live audit: seven public routes plus the real 404; zero axe serious/critical
  findings in light and dark themes; 14 links crawled; zero undersized targets.
- Independent desktop demo and dark 390 px demo: zero axe serious/critical
  findings. Mobile had no horizontal overflow at normal or 200% text size.
- Keyboard focus starts on Skip to main content with a visible 3 px fired-clay
  outline. The full teacher and student keyboard flows passed.
- Reduced motion produced zero running animations.
- Service worker was activated and controlling `/demo`; `update()` completed,
  and the populated demo reloaded offline.
- Root headers include CSP with response-header `frame-ancestors 'none'`, HSTS,
  `nosniff`, `Referrer-Policy: no-referrer`, and restrictive Permissions Policy.
- HTML, service worker, and manifest revalidate. Hashed JS/CSS/images use
  `public, max-age=31536000, immutable`.
- Mobile Lighthouse rerun: **98 performance, 100 accessibility, 100 best
  practices, 100 SEO**; LCP 1.050 s, TBT 160 ms, CLS 0, transfer 39,074 bytes.

## Rate limiting

- Product backend: a 150-request same-client burst to an API read produced 127
  normal `404` responses and 23 `429` responses while the bucket refilled.
  Every `429` had `Retry-After: 0`. Source and unit tests define a 120-request
  burst with one request per second refill.
- Sociobot product-license verification: a 180-request same-client burst
  produced 31 normal `200` invalid-license verdicts and 149 `429` responses.
  Every `429` had `Retry-After: 4`; the observed allowance was approximately
  30 requests before throttling (one refill occurred during the run).

## Defects by severity

### Critical / release-blocking

1. **Private records intermittently disappear because production runs multiple
   unmounted SQLite replicas.** Fresh student, review, and receipt reads failed
   47–53% of the time. New records are also lost when their replica is replaced.
   This violates the core job-to-be-done, the documented durability promise,
   and the mandatory backend persistence topology.

### High, medium, low

No additional product defects were observed.

## Required release action

Redeploy this exact candidate through `scripts/deploy-durable-container.sh`.
Before reconsidering release, confirm `minReplicas = maxReplicas = 1`, one
running replica, Azure File mounted at `/app/data`, and then create a fresh
check-in and prove student, review, and receipt records survive a forced new
revision. No product-code change is indicated by this review.
