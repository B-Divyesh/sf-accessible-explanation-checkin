# Independent verification 3 — FAIL

- Work order: `accessible-explanation-checkin-verify-3`
- Verified: 2026-08-29 UTC
- Candidate: `96472326c1088487c69f739d97e3a3639f3cb4ed`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>

## Verdict

**FAIL.** The deployed frontend and `/health` identify the requested candidate,
the product is clear on first read, and the local implementation passes its
functional, accessibility, privacy, build, and policy suites after compilation.
The real teacher-to-student workflow is nevertheless unreliable in production:
two of every three requests for a newly created private link return 404 because
the live Container App is running three replicas without its declared durable
volume. In addition, the first required claim command times out from a clean
checkout during its cold Rust build. Either finding blocks release under the
acceptance contract.

## Release-blocking defects

### Critical — live records exist on only one of three replicas

Fresh production evidence reproduced the deployment-only failure:

- A new check-in returned `201`.
- After 1.5 seconds, 40 simultaneous reads of its student link returned
  **13 × 200 and 27 × 404**.
- Forty simultaneous valid submissions returned **13 × 201 and 27 × 404**.
  The 404 body was “That private link is not valid. Check that you copied the
  whole link.” These were not quota failures, which correctly use 409.
- A separate new check-in read 30 times sequentially returned the exact pattern
  `404, 404, 200` ten times: **20 × 404 and 10 × 200**.

The Azure control plane confirms the cause. The only active revision,
`sf-accessible-explanation-9c1a54--0000033`, reports `replicas: 3`. The live
template has `minReplicas: 1`, `maxReplicas: 3`, `volumes: null`, and no volume
mount on the app container. This contradicts the repository deployment-policy
claim of one replica with an Azure File share at `/app/data`. Each live replica
therefore uses a separate container-local SQLite snapshot.

Evidence:

- `.factory/evidence/verification-3-live-persistence.json`
- `.factory/evidence/verification-3-live-topology.json`

The primary job cannot be accepted while a teacher's private link fails for
most student and review requests. Apply the repository's durable deployment
settings to the live Container App, confirm one replica and the mounted share,
then repeat create/read/submit checks across independent connections and a
restart.

### High — first declared claim test fails in a clean checkout

After `npm ci` in a detached clean worktree at the candidate SHA, the first
manifest entry was run exactly as declared:

```text
npm run test:claims -- --grep @claim:demo-isolation
Error: Timed out waiting 120000ms from config.webServer.
```

The Playwright web-server command includes `cargo run`; its cold dependency
compile exceeded the configured 120-second startup timeout. The next command
finished compiling the backend, and `demo-isolation` then passed 2/2 when
rerun warm. `npm run test:all-claims` also passed all 18 commands warm. This
separates sound demo behavior from a non-reproducible-from-clean claim gate.
The claims contract says any failing declared test from the clean clone blocks
release. Prebuild the backend in the claim runner or allow enough cold-start
time, then prove the manifest from a fresh checkout.

## Mandatory first-read and demo gate

**PASS.** The cold first screen answers all three questions in plain words:

- What: “Collect student reasoning.”
- Who: teachers who need a low-stakes check-in.
- First click: “Try it with sample data,” followed by “Open a populated teacher
  review; nothing is saved.”

One click opened `/demo` with three realistic watershed explanations and the
persistent “Demo — sample data, nothing is saved” banner. Editing used only the
`demo:accessible-explanation-checkin:review` key, Reset restored the seed note,
Start for real opened creation, and no demo API request was made. The demo also
reloaded offline after service-worker control.

## Claims manifest results

`.factory/claims.json` exists and contains 18 entries. Every declared command
was executed separately after `npm ci`.

| Claim | Clean installed run |
| --- | --- |
| `demo-isolation` | **FAIL** — web-server cold-start timeout; PASS 2/2 warm |
| `demo-reset` | PASS 2/2 |
| `sample-csv-export` | PASS 2/2 |
| `keyboard-demo` | PASS 2/2 |
| `offline-demo` | PASS 2/2 |
| `no-account-needed` | PASS 2/2 |
| `voice-retention-control` | PASS (desktop fixture; mobile project intentionally skipped) |
| `voice-retention-deletion` | PASS |
| `free-response-limit` | PASS (desktop fixture; mobile project intentionally skipped) |
| `no-automated-judgment` | PASS (desktop fixture; mobile project intentionally skipped) |
| `student-keyboard-flow` | PASS (desktop fixture; mobile project intentionally skipped) |
| `student-review-workflow` | PASS (desktop fixture; mobile project intentionally skipped) |
| `privacy-request-boundary` | PASS (desktop fixture; mobile project intentionally skipped) |
| `classroom-plus-limits` | PASS |
| `billing-license-fixture` | PASS 2/2 |
| `external-checkout` | PASS (desktop fixture; mobile project intentionally skipped) |
| `runtime-container-policy` | PASS |
| `durable-deployment-policy` | PASS static policy inspection; contradicted by live configuration |

Warm confirmation: `npm run test:all-claims` reported
`PASS: 18 claim commands completed.` Landing and README promises were
cross-checked against the manifest; no unlisted material product claim was
found.

## Clean-checkout build and automated gates

The isolated worktree was clean and detached at the candidate SHA before
installation.

| Check | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages, 0 reported vulnerabilities |
| `npm test` | PASS — TypeScript, 4 Vitest tests, 11 Rust tests, deployment policy |
| `npm run build` | PASS — exact Vite production build emitted `dist/` |
| `npm run test:e2e` | PASS — 38 passed, 8 intentional skips, 0 failed across desktop and 390 px mobile |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm run test:deploy-helper` | PASS |
| `npm run test:container-identity` | PASS |
| `npm run test:runtime-policy` | PASS — unprivileged runtime wrote its durable snapshot |
| `npm run test:deployment-policy` | PASS — source policy inspection only |

Docker/Podman is not installed in the verifier container, so a full image build
was unavailable. The release binary was built and exercised directly. Started
in a fresh directory with only `PORT=18194`, it logged every optional setting as
`generated_default`, served health, retained a created check-in across graceful
stop/start, and required no secret environment variable.

## Live identity, workflow, and backend boundaries

- `/health` returned `200` with build SHA
  `96472326c1088487c69f739d97e3a3639f3cb4ed`.
- Live root HTML matched clean `dist/index.html` byte-for-byte (SHA-256
  `8ff3e0f37547a093e9a3876b3a46b46277728bc874d3eadc15e3785485b05996`).
  The JS, CSS, and service worker hashes also matched.
- A single live browser journey did complete create → student submission →
  teacher review → reload, but the multi-connection checks above show that
  success depends on which replica receives each request.
- Exact accepted boundaries were 120 title characters, 1,200 prompt
  characters, 4,000 explanation characters, confidence 5, and 7-day free
  voice retention. Invalid title, retention 8, confidence 0, blank explanation,
  malformed voice, unknown tag, and 1,001-character teacher note each returned
  an actionable 400; valid recovery then saved and reloaded.
- Receipt and CSV returned 200. A spreadsheet-formula student name was escaped
  in CSV output.
- Local 40-way quota tests returned exactly 35 × 201 and 5 × 409. The live
  quota cannot be meaningfully reached across the broken replica boundary.
- A live 100-request `/health` concurrency smoke returned 100 × 200 in 449 ms.

## Rate limiting

The API uses one shared governor layer over its server routes. A fresh client
sent 150 concurrent requests to a real API route and received **120 allowed
responses followed by 30 × 429**. Every 429 included `Retry-After: 0`; a second
client remained unblocked. The observed burst allowance is therefore **120
requests per client**, refilling at one request per second. Health is also under
the layer, which is permitted. Evidence:
`.factory/evidence/verification-3-rate-limit.json`.

## Accessibility, responsive behavior, and browser quality

- The supplied `verify-url.sh` passed: title, `lang=en`, one H1, main landmark,
  image alt text, labeled buttons, and no console errors.
- The independent Playwright/Axe audit covered `/`, `/demo`, `/create`,
  `/pricing`, `/privacy`, `/terms`, and the real HTTP 404 in light and dark
  modes: **0 serious/critical violations**, 0 undersized targets, and 0 console
  or page errors.
- The 390 px layout had no horizontal overflow; every tested target was at
  least 44 px. At 200% root text size all routes passed. One first audit run
  transiently reported `/pricing` overflow, but an immediate full rerun and 12
  isolated repeats measured `scrollWidth === clientWidth === 390`; it was not
  reproducible.
- Keyboard Tab exposed the skip link at `top: 8px` with a 3 px designed focus
  outline; Enter moved focus to `main`. Route navigation moves focus to and
  announces the new H1. Teacher and student keyboard flows passed.
- Reduced motion produced no button transform, no loader animation, 0.01 ms
  transitions, and automatic rather than smooth scrolling.
- No dialog/custom-widget focus issue was present. Native form controls have
  bound labels and errors are announced by the tested summary/live regions.

Evidence: `.factory/evidence/verification-3-live-audit.json`.

## Privacy, PWA, headers, and caching

- Cold landing, demo, and the complete classroom browser flow contacted only
  the product origin. The demo made zero API calls. No cookies, analytics,
  advertising, model endpoints, third-party scripts, or CDN fonts were seen.
- Checkout was contacted only by its explicit action. The catalog reports $39
  USD, and the production Sociobot endpoint returned 303 to
  `checkout.dodopayments.com`. No direct payment provider is embedded.
- The service worker activated at `/sw.js`; `registration.update()` completed
  with the worker still activated and cache `check-in-shell-v2`. A subsequent
  offline `/demo` reload retained its title, H1, and all three samples.
- HTTPS redirect, CSP, HSTS, Permissions Policy, `nosniff`, Referrer Policy,
  and request IDs were present. Private API/bearer-link responses use
  `private, no-store`; hashed assets use one-year immutable caching; shell and
  service worker require revalidation.
- The product requires no sign-in, so the Entra tenant check is not applicable.

## Performance and size

Production output is 38.78 KB raw / 12.48 KB gzip JavaScript and 19.30 KB raw /
5.16 KB gzip CSS. The largest shipped hero derivative is 56.60 KB. These are
well inside the supplied 200 KB JS, 50 KB CSS, and 300 KB hero budgets.

Fresh mobile Lighthouse scores were Performance **90**, Accessibility **100**,
Best Practices **100**, and SEO **100**. FCP was 981 ms, LCP 1,149 ms, CLS 0,
and total transfer was 38,690 bytes. Evidence:
`.factory/evidence/verification-3-lighthouse-summary.json`.

## Handoff recommendation

Do not release. First correct the live Container App to one replica with the
Azure File `/app/data` mount, then prove cross-connection and restart
persistence. Separately make the first claims command reliable from a cold
checkout. Re-run every claim from a new clean clone before reassessment.
