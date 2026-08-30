# Independent verification 14 — FAIL

- Work order: `accessible-explanation-checkin-verify-14`
- Candidate commit: `0f0421dd4ea5b076ff61f8cc90abba47b27d2841`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-30 UTC

## Verdict

**FAIL — release blocked.** The deployed HTML, hashed asset ETag, and `/health`
all identify the requested candidate, and most local and browser checks pass.
Two required claims fail against fresh external/live evidence: the paid checkout
catalog is unavailable (503), and the live Container App is allowed three
replicas although the durable SQLite contract requires exactly one.

## First read and demo

**PASS.** A cold visit to `/` returned 200 with the title *Accessible
Explanation Check-in — Collect student reasoning*. The first screen says
“Collect student reasoning,” names teachers needing a low-stakes check-in, and
puts **Try it with sample data** beside “Open a populated teacher review;
nothing is saved.” One click opened the seeded watershed review with three
responses plus the persistent **Demo — sample data, nothing is saved** banner,
**Reset demo**, and **Start for real**.

## Release-blocking findings

### Critical — live durable SQLite topology permits multiple replicas

The exact final command in the declared `durable-deployment-policy` claim
fails against the real Azure control plane:

```text
$ npm run verify:live-topology
ERROR: live topology check failed: expected minReplicas=maxReplicas=1;
observed minReplicas=1 maxReplicas=3
```

This repeats the prior deployment-only failure class. A SQLite writer must be
single-replica under this product's own deployment contract; permitting three
instances risks split private student, receipt, and review records. The local
deployment fixture, local durable-workflow fixture, and topology fixture pass,
but they do not establish the live topology.

Required remediation: deploy the candidate through the durable wrapper and
prove `minReplicas=1`, `maxReplicas=1`, one active ready/running revision, and
the Azure File mount at `/app/data`; then rerun the live topology and
cross-revision workflow checks.

### High — Classroom Plus checkout claim is unavailable

The exact `@claim:external-checkout` test failed twice. Its first live request
to `https://api.sociobot.in/api/v1/products` received **503**, while the claim
expects 200 and then a 303 redirect from the product checkout endpoint to a
Dodo session. A direct no-payment request to the documented checkout URL also
returned 503. No payment details were entered.

```text
Expected: 200
Received: 503
frontend/tests/claims.spec.ts:431
```

The page's $39 one-time-purchase copy and external Sociobot link are present,
but the observable checkout promise is presently broken. Under the claims
contract, this is release-blocking even though the failure is at the billing
gateway rather than the browser UI.

Required remediation: restore the public Sociobot catalog and checkout
availability, then rerun the exact claim until it observes the expected catalog
record and Dodo 303 redirect.

## Claims gate

`.factory/claims.json` exists with 25 declared claims. As directed, the first
claim command was attempted before installing dependencies and could not import
the uninstalled `@playwright/test`; after `npm ci` (86 packages, zero reported
vulnerabilities), every manifest command was invoked sequentially through its
shipped demo entry point. The two failures above are reproducible fresh
failures of declared tests:

| Claim | Result | Evidence |
| --- | --- | --- |
| `external-checkout` | **FAIL** | Exact Playwright claim retried once: live Sociobot catalog 503, expected 200. Trace saved under `frontend/test-results/`. |
| `durable-deployment-policy` | **FAIL** | Exact composed claim fails at `npm run verify:live-topology`: max replicas 3, expected 1. |
| Supporting demo, storage, voice, workflow, privacy, runtime, and fixture checks | PASS/no additional failure observed | Full local claim suite and individual manifest sequence exercised them; `npm test` passed its 5 frontend and 13 Rust tests plus deployment fixtures. |

## Independent positive evidence

- **Candidate identity:** root and hashed asset ETags, and `/health`, all equal
  `0f0421dd4ea5b076ff61f8cc90abba47b27d2841`.
- **Build and code quality:** `npm run build`, `cargo build --release --locked`,
  `cargo fmt --all -- --check`, and strict `cargo clippy` pass. Build output is
  12.43 kB gzip JavaScript and 5.19 kB gzip CSS.
- **Core flow/recovery:** a fresh live teacher created private links; a student
  submitted text and confidence; the review saved a tag and private note, which
  persisted on reload. Blank create and student submissions showed required
  field recovery messages.
- **Privacy:** request logs for a fresh demo and the real workflow contained
  only `https://accessible-explanation-checkin.sociobot.in`; no model,
  analytics, advertising, font-CDN, or other third-party request appeared.
  No sign-in is offered, so Entra tenant verification is not applicable.
- **Accessibility:** independent axe scans at desktop and 390 px had zero
  serious/critical findings. `lang=en`, one `<h1>`, one `<main>`, skip link,
  meaningful hero alt text, keyboard navigation, and a visible 3 px focus
  outline were observed. At 390 px there was no horizontal overflow. Reduced
  motion uses `scroll-behavior: auto`.
- **PWA:** after `registration.update()`, `/demo` remained controlled by
  `/sw.js`; the seeded review reloaded offline.
- **Headers and caching:** HTML revalidates; hashed assets are immutable for a
  year; private API responses are `private, no-store`. Live responses include
  HSTS, `nosniff`, `no-referrer`, Permissions Policy, and a response-header CSP
  with `frame-ancestors 'none'`.
- **Rate limiting:** 140 concurrent harmless API reads from one forwarded test
  IP returned exactly 120 × 404 and 20 × 429. The observed burst allowance is
  120 (configured refill: one request/second); every 429 included
  `Retry-After: 0`.

## Other note

The repository has no `verify-url.sh` in its root or `PATH`, so that requested
worker script could not be run. Equivalent direct browser checks verified
title, language, main landmark, image alt text, and console cleanliness. This
is a low QA-tooling gap, not the reason for the FAIL.
