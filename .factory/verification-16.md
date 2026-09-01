# Independent verification 16 — FAIL

- Work order: `accessible-explanation-checkin-verify-16`
- Candidate commit: `9b90dec842d89ae5f7ffa77edd53224260adca33`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-09-01 UTC

## Verdict

**FAIL — release blocked by a required claim test that fails from a clean
clone.** The live deployment has the exact candidate identity and the previous
production persistence defect is repaired. Product behavior, accessibility,
privacy, rate limiting, build output, and live topology passed independent
checks. However, the mandatory `durable-deployment-policy` claim and the
repository's aggregate `npm test` both fail when the repository is cloned to a
path other than `/work/repo`.

## Release-blocking finding

### High — deployment policy claim is tied to `/work/repo`

A fresh clone was made from the supplied GitHub repository at the exact
candidate SHA under `/tmp/aec-verification16-clean-9b90dec`. It was clean
before installation. `npm ci` installed 86 locked packages and reported zero
vulnerabilities.

The exact command from claim 25 failed consistently:

```text
$ npm run test:deployment-policy
> bash scripts/test-durable-deploy.sh
[exit 1, with no diagnostic]
```

`bash -x scripts/test-durable-deploy.sh` locates the failure at the first
assertion of the helper arguments. The fixture expects the current clone path:

```text
accessible-explanation-checkin /tmp/aec-verification16-clean-9b90dec Dockerfile 8080
```

but `scripts/deploy-durable-container.sh` defines:

```sh
repo=${2:-/work/repo}
```

Therefore `npm run deploy`, which supplies no positional arguments, always
passes `/work/repo` instead of the current repository. The same fixture passes
only when executed from `/work/repo`, masking the defect. This also makes
`npm test` exit 1 in the fresh clone after its TypeScript, Vitest, Rust, and
container-name checks pass.

Required remediation: derive the default repository path from the deployment
script's own location (or pass the current repository explicitly), make the
fixture print a useful mismatch, and rerun every claim from a fresh clone in a
different path.

## Required first checks

### Cold first read and demo — PASS

A cold live desktop visit returned 200 with no console errors and only
same-origin requests. The first screen answers the required questions in plain
words:

- What it does: **“Collect student reasoning.”**
- Who it is for: teachers who need a low-stakes check-in.
- What to do first: **“Try it with sample data,”** followed by “Open a
  populated teacher review; nothing is saved.”

One click opens `/demo`, showing three realistic watershed explanations and a
persistent **Demo — sample data, nothing is saved** banner with **Reset demo**
and **Start for real**.

### Claims gate — FAIL (24 passed, 1 failed)

Every `.factory/claims.json` entry was invoked individually after `npm ci` in
the fresh clone. The browser claims use the documented `/demo` or `?demo=1`
entry. Claim 25's compound command short-circuited at its first failing command;
its three remaining commands were then run separately and passed.

| Claim | Result | Evidence |
| --- | --- | --- |
| `demo-isolation` | PASS | 2 Playwright projects passed |
| `demo-reset` | PASS | 2 Playwright projects passed |
| `demo-exit-disposal` | PASS | 2 Playwright projects passed |
| `sample-csv-export` | PASS | 2 Playwright projects passed |
| `keyboard-demo` | PASS | 2 Playwright projects passed |
| `offline-demo` | PASS | 2 Playwright projects passed |
| `student-draft-local` | PASS | 2 Playwright projects passed |
| `no-account-needed` | PASS | 2 Playwright projects passed |
| `stored-record-shape` | PASS | Exact Rust test passed |
| `recent-links-local` | PASS | Desktop passed; duplicate mobile project intentionally skipped |
| `voice-retention-control` | PASS | Desktop passed; duplicate mobile project intentionally skipped |
| `voice-recording-limits` | PASS | Desktop passed; duplicate mobile project intentionally skipped |
| `voice-retention-deletion` | PASS | Exact Rust test passed |
| `teacher-voice-deletion` | PASS | Exact Rust test passed |
| `free-response-limit` | PASS | Desktop concurrency test passed |
| `no-automated-judgment` | PASS | Desktop API-shape test passed |
| `student-keyboard-flow` | PASS | Desktop keyboard test passed |
| `student-review-workflow` | PASS | Desktop end-to-end test passed |
| `privacy-request-boundary` | PASS | Desktop outgoing-request test passed |
| `classroom-plus-limits` | PASS | Exact Rust test passed |
| `billing-license-fixture` | PASS | 2 Playwright projects passed |
| `refund-license-contract` | PASS | 2 Playwright projects passed |
| `external-checkout` | PASS | Desktop live check passed |
| `runtime-container-policy` | PASS | Release server ran unprivileged and wrote its durable snapshot |
| `durable-deployment-policy` | **FAIL** | `npm run test:deployment-policy` exits 1 outside `/work/repo` |

Independent execution of the remaining claim-25 components passed:
`npm run test:live-durability-checker`, `npm run test:live-topology`, and
`npm run verify:live-topology`.

No claim-like landing or README statement was found without a corresponding
entry in `.factory/claims.json`.

## Exact live identity and repaired persistence — PASS

`/health` returned:

```json
{"build_sha":"9b90dec842d89ae5f7ffa77edd53224260adca33","status":"ok"}
```

The root, service worker, and hashed assets carry the same SHA in their ETags.
Fresh local and live assets matched byte for byte:

- JS SHA-256: `e72750bade996df55b72ac2fd7bcbb6e2914fc62b2d500ad282c92502dc8e921`
- CSS SHA-256: `c8311b6ed07628ab1e38f70d44625a21f679bbf5ed63f246b11c0a54b2101ced`

The product-scoped live topology check passed:

- container app `sf-accessible-explanation-9c1a54`
- revision `sf-accessible-explanation-9c1a54--0000134`
- image tag `9b90dec842d8`
- exactly one active, running, ready replica; min/max `1/1`
- healthy, `RunningAtMaxScale`
- volume `data` mounted at `/data`
- storage binding `aec-accessible-explanati-9c1a54`
- share `sf-accessible-explanation-checkin-data`

A fresh live teacher/student/review flow created separate private links,
submitted an explanation, loaded its receipt, saved teacher tags and notes,
and retained the saved review after reload. A separate live concurrency check
accepted exactly 35 of 40 simultaneous submissions, rejected the other five
with HTTP 409, and returned all 35 records on 24/24 repeated review reads. The
deployment-only data-loss defect from verification 15 was not reproduced.

## Build and automated checks

- `npm run build`: PASS; `dist/` produced 38.93 kB raw / 12.43 kB gzip JS and
  19.42 kB raw / 5.19 kB gzip CSS.
- `cargo fmt --all -- --check`: PASS.
- `cargo clippy --all-targets --locked -- -D warnings`: PASS.
- `cargo build --release --locked`: PASS.
- `npm run test:container-identity`: PASS.
- `npm run test:e2e`: PASS; desktop app 9 passed / 2 mobile-only skips,
  desktop claims 19 passed, mobile app 11 passed, mobile claims 10 passed with
  expected duplicate-project skips.
- `npm test`: **FAIL** only at `scripts/test-durable-deploy.sh`; 5 Vitest and 17
  Rust tests passed before the failure.

A Docker CLI was not available in the verifier container. The repository's
non-root runtime claim, release build, Dockerfile identity check, and exact
running container identity provide the available container evidence.

## Live functional, boundary, and recovery checks

- Normal teacher → student → receipt → review flow: PASS.
- CSV download, print control, review tags/notes persistence: PASS.
- Title boundary: 120 characters accepted; 121 rejected with HTTP 400 and a
  precise error.
- Prompt boundary: 4 characters accepted; 3 rejected with HTTP 400.
- Free voice retention: 1–7 days accepted; 0 and 8 rejected with HTTP 400.
- Student validation: missing text/voice and confidence 0 each returned clear
  HTTP 400 errors; a valid keyboard-only retry reached the receipt.
- Voice boundary: exactly 4 MiB accepted; 4 MiB + 1 byte rejected with HTTP
  413 and recovery guidance.
- Voice deletion: early deletion returned 200; later voice fetch returned 410
  while text, receipt, tags, note, and follow-up remained.
- Invalid private link: HTTP 404 with a clear copy-the-whole-link message.
- Unknown page: designed response with HTTP 404 and a route back.

## Accessibility, mobile, and PWA

The live audit covered `/`, `/demo`, `/create`, `/pricing`, `/privacy`,
`/terms`, and the 404 route at 390 × 844 in light and dark themes:

- zero axe serious/critical findings on every route and theme;
- one `<h1>`, one `<main>`, `lang=en`, route-specific title/canonical metadata;
- no controls under 44 px and no horizontal overflow, including at 200% text;
- first keyboard stop is the skip link; it has a 3 px solid focus outline and
  moves focus to main content;
- full student form completed using Tab, typing, arrow keys, and Enter;
- route transitions restore focus to `<h1>` and announce the new page;
- reduced motion yields 0.01 ms transitions and `scroll-behavior: auto`;
- no console or page errors.

The service worker update completed with `sw.js` activated and cache
`check-in-shell-v2`. `/demo` then reloaded offline and showed “Watershed
reasoning.” Evidence:
[live audit](evidence/verification-16-live-check.json),
[mobile demo](evidence/verification-16-live-demo-mobile.png), and
[URL verification](evidence/verification-16-verify-url/verify.json).

## Privacy, headers, caching, and rate limits

- The demo made no API request and used only the
  `demo:accessible-explanation-checkin:review` browser namespace.
- The real classroom workflow contacted only the product origin. No analytics,
  advertising, model, third-party script, or font-CDN request was observed.
- The checkout left the product only after explicit activation and redirected
  with HTTP 303 to `checkout.dodopayments.com`; catalog price was USD 39 once.
- The product has no sign-in, so the Entra tenant requirement is not applicable.
- HTML, health, and `sw.js` revalidate; hashed assets use one-year immutable
  caching; private API responses use `private, no-store`.
- Responses include CSP with `frame-ancestors 'none'`, HSTS, `nosniff`,
  `Referrer-Policy: no-referrer`, and Permissions Policy.
- Product API: a fresh 180-request same-client burst produced 120 × 404 and
  60 × 429. Every 429 had `Retry-After: 0`; a second client remained unblocked.
  The observed allowance is 120 burst requests with one request/second refill.
- Sociobot product-license verification: 60 requests produced 30 × 200 and
  30 × 429. Every 429 had `Retry-After: 4`; observed burst allowance is 30.

## Performance

Fresh mobile Lighthouse: Performance 99, Accessibility 100, Best Practices
100, SEO 100; FCP 0.995 s, LCP 1.198 s, TBT 119 ms, CLS 0. The hero AVIF is
56.6 kB, and the application loads no external font or runtime script.

## Defects by severity

1. **High / release-blocking:** The mandatory durable deployment claim and
   aggregate `npm test` fail in a fresh clone outside `/work/repo` because the
   deployment helper hard-codes `/work/repo` as its default repository path.

No live functional, persistence, accessibility, privacy, security-header,
rate-limit, cache, bundle, or performance defect was found.
