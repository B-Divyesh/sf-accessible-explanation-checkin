# Independent verification 20 — FAIL

- Work order: `accessible-explanation-checkin-verify-20`
- Candidate: `63757a06cf7e8c8770a72f0adbcd2e8bc16f0f13`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-09-02 UTC

## Verdict

**FAIL — release-blocking deployment identity defect.** The candidate is
functionally present at the URL (`/health` and HTML ETags report the candidate
SHA), but the required declared claim test rejects the deployed image because
its embedded build identity is still `2182c924b7b2`. A candidate cannot pass
until the running image and its declared build identity agree.

## Clean-checkout claim gate

A detached, clean worktree at the exact SHA was created at
`/tmp/aec-clean-20`; `git status --short` was empty and `npm ci` completed
with 86 packages and zero reported vulnerabilities. I then ran every command
listed in `.factory/claims.json` through `npm run test:all-claims`.

The first 26 claim commands passed, including isolated demo/reset/disposal,
CSV, offline reload, local draft recovery, keyboard workflows, voice limits
and deletion, 35-response concurrency, no automated judgment, same-origin
privacy requests, license fixtures, external checkout, and non-root durable
runtime. The 27th command, `durable-deployment-policy`, failed at its final
live topology check:

```
ERROR: live topology check failed: image
sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:63757a06cf7e
does not identify build 2182c924b7b2
```

This is a mandatory claim test, so it is a release blocker even though the
preceding policy, durability-workflow, and topology fixture subchecks passed.

## First read and demo — PASS

Fresh live load plainly states **“Collect student reasoning”**, says it is for
teachers who need a low-stakes check-in, and presents **“Try it with sample
data”** with the adjacent result “Open a populated teacher review; nothing is
saved.” One click opens `/demo` with a watershed review, three sample
explanations, and the persistent demo banner with Reset demo and Start for
real.

## Local quality gates — PASS

- `npm test`: PASS — TypeScript, 5 Vitest, 18 Rust tests, policy/durability
  fixtures, and topology fixture tests.
- `npm run build`: PASS — `dist/` produced.
- `cargo fmt --check`: PASS; `cargo clippy --all-targets -- -D warnings`: PASS.
- `npm run test:e2e`: PASS — desktop and 390 px mobile suite completed; only
  intentional project-specific duplicate skips occurred.
- Production first-load bundle: JS 40.34 kB raw / 12.76 kB gzip; CSS 19.47 kB
  raw / 5.20 kB gzip.

## Live product QA — PASS except identity

- `/health` returns 200 with the exact candidate SHA; root HTML and JS ETags
  also return the candidate SHA. This conflicts with the image identity failure
  above and is why deployment remediation must re-establish a single source of
  truth rather than treating the UI response alone as sufficient.
- Real UI flow passed: create a check-in, show invalid missing-explanation
  recovery, submit text/confidence, receive a receipt, save teacher tag/note,
  export CSV, and delete the test record. No test data was left behind.
- Desktop and 390 px reduced-motion demo had no horizontal overflow or page
  errors. Axe found zero serious/critical issues in both. Keyboard tab order
  starts with the skip link and reaches all primary navigation/actions.
- `verify-url.sh` passed live root: HTTP 200, title, `lang=en`, one h1, main,
  image alt coverage, labeled buttons, and zero console errors.
- Browser request logging across demo and the real flow recorded only
  `https://accessible-explanation-checkin.sociobot.in`; no analytics or
  third-party font/script requests occurred. Headers include CSP,
  `frame-ancestors 'none'`, HSTS, nosniff, no-referrer, and immutable hashed
  asset caching.
- API rate-limit test: 150 same-client reads yielded 120 normal 404 responses,
  then 30 HTTP 429 responses. `Retry-After: 0` was present on every observed
  429 (policy: burst 120, one request/second refill).

Lighthouse was attempted with the installed Chromium. Its tab crashed during
the screenshot artifact phase, so its apparent 100 scores are not accepted as
evidence; this is an environment/tool failure, not a product finding.

## Defects

### Critical / release-blocking

1. **Deployed image identity does not match candidate** — the mandatory
   `durable-deployment-policy` claim fails because image tag
   `63757a06cf7e` identifies build `2182c924b7b2`. Rebuild/redeploy the
   candidate image with the correct build args, then rerun
   `npm run verify:live-topology` and the full claim gate.

### Other

No additional product defect was found in this verification.

## Reproduce

```sh
npm ci
npm run test:all-claims
npm test
npm run build
cargo fmt --check
cargo clippy --all-targets -- -D warnings
npm run test:e2e
npm run verify:live-topology
```
