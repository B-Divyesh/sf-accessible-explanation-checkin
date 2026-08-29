# Independent verification 10 — FAIL

- Work order: `accessible-explanation-checkin-verify-10`
- Candidate and live build: `00eb5aa5561fe46fd0ab5a02adf9799f70f52418`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

## Verdict

**FAIL — release blocked (critical).** The live site identifies the requested candidate SHA, but its backend is deployed as two independent SQLite writers with no Azure File mount. A freshly created private check-in alternates between `200` and `404` depending on the replica that receives the request. A student can receive a submission success response and then be unable to open the receipt. This loses the real job-to-be-done's student-to-teacher record.

## First read and one-click demo

**PASS.** A cold live desktop page says what it does — **“Collect student reasoning”** — who it is for — teachers needing a low-stakes text or voice check-in — and what to click first: **“Try it with sample data”**, followed by “Open a populated teacher review; nothing is saved.” `/demo` loads three watershed explanations and a persistent “Demo — sample data, nothing is saved” banner with **Reset demo** and **Start for real**. A fresh 390 px request log contained only this product origin (`/demo`, its self-hosted JS, and CSS), with no console errors.

## Claims gate

`.factory/claims.json` exists with 25 unique claims. The required initial clean-clone claim invocation was attempted before dependency installation and could not import the uninstalled `@playwright/test` package. After `npm ci` (86 packages; zero audit vulnerabilities), the sequential runner exercised the declared commands. The browser, Rust, runtime, and fixture commands passed; the final listed claim command failed exactly where it invokes the live gate:

```text
$ npm run test:deployment-policy && npm run test:live-durability-checker \
  && npm run test:live-topology && npm run verify:live-topology
...
ERROR: live topology check failed: expected minReplicas=maxReplicas=1;
observed minReplicas=1 maxReplicas=3
```

This is a release-blocking failed claim: `durable-deployment-policy`. The first three commands above are fixtures or local harnesses and pass; they do not establish the state of the deployed service.

## Critical finding

### Critical — live private records are split across ephemeral replicas

Fresh production evidence:

- `/health` returns the full candidate SHA.
- Azure control-plane queries for `sf-accessible-explanation-9c1a54` report latest/ready revision `...--0000082`, image tag `00eb5aa5561f`, `minReplicas: 1`, **`maxReplicas: 3`**, **two running replicas**, and `volumes: null` / `mounts: null` (no `/app/data` Azure File mount).
- In a fresh browser: create `201`, fetch the student check-in `200`, submit `201`, then fetch the returned receipt `404`; the UI shows “We could not open this receipt” and logs the failed request.
- In an independent direct flow, creation returned `201` but submission returned `404`. Twenty reads of each newly created student and review link alternated exactly ten `200`s and ten `404`s.
- The repository's live audit also failed at the same point, timing out after 30 seconds waiting for “Your check-in receipt” after a real successful form submission.

This violates the brief's record/review workflow, the backend durable-storage contract, and the `durable-deployment-policy` claim. It is not corrected by the source-level mocked deployment tests.

Required remediation: deploy one active, running replica only (`minReplicas=maxReplicas=1`), attach the required read-write Azure File share to `/app/data`, then redeploy the candidate and prove create → submit → receipt → review persistence across a revision replacement. Do not release until `npm run verify:live-topology` passes and repeated private-link reads are all successful.

## Other verification evidence

The following checks passed locally from this checkout:

| Check | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages, 0 vulnerabilities |
| `npm test` | PASS — TypeScript, 5 Vitest, 13 Rust tests, deployment fixtures |
| `npm run test:e2e` | PASS — desktop and 390 px Playwright shards; final run reported no failed tests |
| `npm run build` | PASS — `dist/` produced |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --all-features -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm run test:runtime-policy` | PASS — release server wrote durable data as non-root |
| deployment helper/container identity fixtures | PASS |

The exact production bundle is 38.93 kB raw / **12.43 kB gzip JavaScript** and 19.30 kB raw / **5.16 kB gzip CSS**, within the static budget. A direct Docker build could not be run because this verifier image has no Docker CLI. Lighthouse could not launch the Playwright-supplied Chromium through the available Lighthouse CLI (`Unable to connect to Chrome`); this does not alter the release-blocking persistence evidence.

Before the live audit reached the broken workflow, it successfully checked all seven public routes at 390 px in light and dark mode: correct status/title/canonical/lang/one h1/main, no serious or critical Axe findings, no undersized controls or horizontal overflow at 200% text, working route focus announcements, valid crawled links, demo reset/exit isolation, and offline demo reload. Keyboard and mobile student flows also passed their local claim tests.

Privacy/header/rate-limit checks on the live candidate passed: the cold demo made only same-origin requests; no analytics, model, advertising, CDN-font, or third-party script request was observed. Root is revalidated, hashed assets are immutable, and private API responses are `private, no-store`. CSP is an HTTP header with `frame-ancestors 'none'`; HSTS, `nosniff`, no-referrer, and Permissions Policy are present. A same-client burst of 180 API reads returned 130 normal `404`s and 50 `429`s; every `429` included `Retry-After: 0`.

The product has no sign-in, so the Microsoft Entra tenant requirement is not applicable. It is not a library or CLI. Its service-worker demo offline reload passed before the live workflow failure.
