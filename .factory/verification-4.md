# Independent verification 4 — FAIL

- Work order: `accessible-explanation-checkin-verify-4`
- Verified: 2026-08-29 UTC
- Candidate: `771b1f4f9f6dc80b89a949cf1f63473f7690ea55`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>

## Verdict

**FAIL.** The candidate's clean local product, claims, build, accessibility,
privacy-boundary, and policy checks pass. The deployed candidate is not
end-to-end usable: its durable SQLite backend is deployed on three independent
replicas with no Azure File mount. A teacher can receive a private link and a
student then receives a 404 on most requests. This is a Critical release
blocker for the product's central teacher → student → review job.

## Required first-read and demo gate

**PASS.** A cold Chromium visit to the live root gave a plain first screen:

- What: “Collect student reasoning.”
- Who: “For teachers who need a low-stakes check-in...”
- First action: “Try it with sample data,” with the adjacent explanation
  “Open a populated teacher review; nothing is saved.”

The one-click action opens the populated watershed review with three realistic
responses and the persistent “Demo — sample data, nothing is saved” banner,
including Reset demo and Start for real. The cold landing made only same-origin
requests and had no console or page errors.

## Critical defect

### Live private records are split between three non-durable replicas

Fresh live API evidence:

1. `POST /api/checkins` returned `201` for a new QA check-in.
2. Twelve immediate reads of its newly issued student token returned **3 × 200
   and 9 × 404**.
3. A valid student submission against that same token returned `404` with
   `That private link is not valid. Check that you copied the whole link.`
4. Twelve reads of the matching review token returned **5 × 200 and 7 × 404**.
5. An independent live Playwright journey created a check-in through the UI,
   opened the generated student URL, and rendered “We could not open this
   check-in”; the browser logged the corresponding 404.

This is not a rate-limit response (the affected responses are 404, not 429).
It is corroborated by the Azure control plane for the exact candidate image:

- active/ready revision: `sf-accessible-explanation-9c1a54--0000038`
- image: `sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:771b1f4f9f6d`
- scale: `minReplicas: 1`, `maxReplicas: 3`; revision state
  `RunningAtMaxScale`; **3 running replicas**
- `volumes: null`; app container has no `volumeMounts`

The repository's deployment-policy test correctly describes the intended one
Azure-File-backed replica, but the actual deployed topology has not applied it.
Use `scripts/deploy-durable-container.sh` (or equivalent deployment action) to
mount `/app/data` and pin the app to exactly one active running replica, then
repeat create/read/submit/review tests across independent requests and after a
restart.

## Checks that passed

### Claims and clean build

`.factory/claims.json` exists with 18 entries. After `npm ci` (86 packages,
0 reported vulnerabilities), every declared command was run from the demo
entry point; all passed:

`demo-isolation`, `demo-reset`, `sample-csv-export`, `keyboard-demo`,
`offline-demo`, `no-account-needed`, `voice-retention-control`,
`voice-retention-deletion`, `free-response-limit`, `no-automated-judgment`,
`student-keyboard-flow`, `student-review-workflow`,
`privacy-request-boundary`, `classroom-plus-limits`, `billing-license-fixture`,
`external-checkout`, `runtime-container-policy`, and
`durable-deployment-policy`.

`npm run test:all-claims` also completed the manifest runner. The local
deployment-policy result is a source/deployment-wrapper test; it does not prove
the live platform topology, which is why it cannot override the Critical live
finding above.

- `npm test`: PASS — TypeScript; 5 Vitest tests; 11 Rust tests; deployment
  policy test.
- `npm run test:e2e`: PASS — 46 checks across desktop Chromium and the 390 px
  mobile project; 38 passed and 8 intended state-changing mobile skips.
- `npm run build`: PASS — `dist/` produced. Initial JS is 38,782 bytes raw /
  12,480 gzip; CSS is 19,296 bytes raw / 5,160 gzip.
- `cargo fmt --all -- --check`, locked `cargo clippy --all-targets -- -D
  warnings`, and `cargo build --release --locked`: PASS.
- Runtime/non-root, Docker build-identity, and deployment-wrapper policy
  scripts: PASS locally.

### Functional, accessibility, privacy, and operations checks

- Local release API: blank assignment and blank student submission returned
  actionable 400 errors; valid creation, submission, private receipt and
  response count recovery passed. The free UI offers 1, 3 and 7-day voice
  schedules; the raw API accepts any 1–7 day value.
- Live candidate identity: root HTML ETag and `/health` build SHA are both
  `771b1f4f9f6dc80b89a949cf1f63473f7690ea55`.
- Live desktop and 390 × 844 mobile checks: no horizontal overflow, one H1,
  `lang=en`, `main`, skip link, visible 3 px focus ring, and no console/page
  errors. Keyboard Tab/Enter reaches the skip link and main content.
- Axe on live `/demo` and `/` at desktop/mobile found **0 serious or critical**
  WCAG 2.0/2.1/2.2 AA violations. Reduced motion reports no running animation.
- Demo request logging observed only the product origin; it made no API calls
  before edits and used no analytics, advertising, or model endpoint. Service
  worker offline demo reload is covered by the passing required claim.
- Live headers: HTTPS, HSTS, `nosniff`, `no-referrer`, Permissions Policy, CSP
  with response-header `frame-ancestors 'none'`, request IDs, shell
  revalidation, and private API `no-store` policy were present. Internal site
  link crawl returned 200 for all public routes and 404 for an unknown route.
- Live API rate-limit test: 150 concurrent read-only invalid-token requests
  from one forwarded client returned **120 × 404 then 30 × 429**. Every 429
  supplied `Retry-After: 0`; observed allowance is a 120-request burst,
  refilling at one request/second.

## Handoff

Do not release this deployment. The product code and deployment wrapper are
buildable, but the factory must apply the durable one-replica Azure File
topology to the live Container App and rerun this verification. No product
source code was modified during verification.
