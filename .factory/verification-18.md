# Independent verification 18 — FAIL

- Work order: `accessible-explanation-checkin-verify-18`
- Candidate: `f886c6fc58113551d1efc52d438cc399bbfa8366`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-09-01 UTC

## Verdict

**FAIL — release blocked.** The candidate itself builds and tests cleanly, but
the live deployment is not this candidate. The required claim runner fails at
its live deployment identity gate, so the candidate cannot be accepted.

`/health`, the HTML ETag, and live asset ETags all identify
`b6ea22ce6875778503e053da80d0b1279bdc02a9`; the candidate is
`f886c6fc58113551d1efc52d438cc399bbfa8366`. The failing claim reports that
the deployed image tag is
`sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:b6ea22ce6875`.

## Required first checks

### Cold first read — PASS for the currently live (old) build

A fresh browser at the root page said, in plain words:

- **What it does:** “Collect student reasoning.”
- **For whom:** “For teachers who need a low-stakes check-in…”
- **First action:** “Try it with sample data,” with the adjacent explanation
  “Open a populated teacher review; nothing is saved.”

One click opened the populated demo. It showed three realistic sample
responses and the persistent **Demo — sample data, nothing is saved** banner
with **Reset demo** and **Start for real**. This satisfies the first-read and
one-click sandbox requirement for the old deployment; it is not evidence that
the candidate was deployed.

### Claims gate — FAIL

In a fresh detached checkout at the exact candidate SHA, `npm ci` completed
with zero reported vulnerabilities. `npm run test:all-claims` ran every
command in `.factory/claims.json` from the demo entry point.

The following 24 claim commands passed:

`demo-isolation`, `demo-reset`, `demo-exit-disposal`, `sample-csv-export`,
`keyboard-demo`, `offline-demo`, `student-draft-local`, `no-account-needed`,
`stored-record-shape`, `recent-links-local`, `voice-retention-control`,
`voice-recording-limits`, `voice-retention-deletion`, `teacher-voice-deletion`,
`teacher-checkin-deletion`, `free-response-limit`, `no-automated-judgment`,
`student-keyboard-flow`, `student-review-workflow`, `privacy-request-boundary`,
`classroom-plus-limits`, `billing-license-fixture`, `refund-license-contract`,
`external-checkout`, and `runtime-container-policy`.

The 25th command, `durable-deployment-policy`, passed its fixture and static
sub-checks but failed its required `npm run verify:live-topology` sub-check:

```
ERROR: live topology check failed: image
sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:b6ea22ce6875
does not identify build f886c6fc5811
```

Some deliberately duplicated mobile project instances were skipped by the
test design after the same desktop assertion passed; the dedicated mobile
suite below exercised its applicable assertions.

## Local candidate verification — PASS

All commands below were run at `f886c6fc…` in the clean candidate checkout:

- `npm test`: PASS — TypeScript check; 5 Vitest tests; 18 Rust tests; deploy,
  durability, and topology fixtures.
- `npm run build`: PASS — `dist/` produced. JS: 40.34 kB raw / 12.76 kB gzip;
  CSS: 19.47 kB raw / 5.20 kB gzip.
- `cargo build --release --locked`: PASS.
- `cargo fmt --all -- --check`: PASS.
- `cargo clippy --all-targets --locked -- -D warnings`: PASS.
- `npm run test:e2e`: PASS — desktop app/claim suites and 390 px mobile
  app/claim suites. Mobile app suite: 12 passed; all functional workflow,
  keyboard, semantic, axe, 44 px target, and 200% text checks passed.

The candidate’s runtime-policy claim also passed: a release server ran as an
unprivileged user and wrote its durable SQLite snapshot.

## Live QA of the deployed old build

The live audit completed successfully, but reports build SHA `b6ea…`, not the
candidate. It verified:

- `/`, `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, and 404: expected
  status, one `h1`, one `main`, `lang=en`, titles, canonical metadata, links,
  and zero serious/critical Axe findings in light and dark treatments.
- Desktop and 390 px mobile: no audited undersized targets or horizontal
  overflow; 200% text retained usable content and navigation.
- Console/page errors: none observed on the cold page or live audit.
- Keyboard: skip link first; route changes focused the new `h1` and announced
  the route. Candidate tests also completed the student keyboard-only flow.
- Demo: isolated `demo:` localStorage, no API request, reset and exit disposal,
  and offline reload after service-worker control.
- Real workflow: create → student text response → receipt → teacher tags,
  notes and follow-up persisted after reload; whole-check-in deletion made
  student/review/receipt links return 404; controlled voice test stopped at
  120 seconds, accepted 4 MiB, rejected 4 MiB + 1 byte, and preserved text
  after early voice deletion.
- Privacy boundary: observed demo and classroom workflow requests were only to
  `https://accessible-explanation-checkin.sociobot.in`; no model, analytics,
  ad, font, or external-script request occurred. Checkout was a user-activated
  303 redirect to Dodo.
- Headers: CSP with `frame-ancestors 'none'`, HSTS, `nosniff`,
  `Referrer-Policy: no-referrer`, and Permissions Policy were present. HTML
  revalidates; hashed JS/CSS are `public, max-age=31536000, immutable`.
- Rate limit: 130 concurrent API reads from a single isolated forwarded client
  produced 120 `404` responses and 10 `429` responses. Each observed `429`
  carried `Retry-After: 0`; source configuration is burst 120 with one
  request-per-second refill. No sign-in exists, so Entra is not applicable.
- Lighthouse mobile on the live old build: Performance 96, Accessibility 100,
  Best Practices 100, SEO 100; LCP 2,397 ms, TBT 0 ms, CLS 0, and 39,236 bytes
  transferred.

## Defects by severity

### Critical / release blocker

1. **Candidate is not deployed.** The public app, `/health`, HTML, asset
   ETags, and the product image all identify `b6ea22…`, rather than requested
   candidate `f886c6…`. This fails the required `durable-deployment-policy`
   claim and prevents validating the candidate end to end in production.

### High, medium, low

No additional defect was found in the locally tested candidate or the old live
build. The release remains a FAIL until the exact candidate is deployed and
the failing identity/continuity claim is rerun successfully.

## Reproduction

```sh
npm ci
npm run test:all-claims
npm test
npm run build
cargo build --release --locked
npm run test:e2e
npm run verify:live-topology
curl -sS https://accessible-explanation-checkin.sociobot.in/health
```
