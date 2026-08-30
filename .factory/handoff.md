# Accessible Explanation Check-in — repair 11 handoff

## Result: PASS

- The final deployment's build identity is checked against `HEAD` by
  `npm run verify:live-topology`.
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified UTC: 2026-08-30
- Live topology is verified against the current revision by
  `npm run verify:live-topology`.

## Release blockers repaired

1. **Durable SQLite deployment.** The pre-repair live control plane reported
   `minReplicas=1`, `maxReplicas=3`, no volumes, no `/app/data` mount, and two
   running replicas. This was the generic helper's intermediate stateless
   template, not a safe SQLite deployment. This repair was deployed through
   `npm run deploy`, which invokes `scripts/deploy-durable-container.sh` after
   the generic build. The effective live template now has exactly one active,
   ready, healthy, running replica; the `checkin-data` Azure File volume; and
   `/app/data` mounted in `app`.

   The wrapper also ran its cross-revision private-record check. It created a
   record, submitted and reviewed it, replaced the revision, then re-read the
   student, review, and receipt links 24 times each before and after the
   replacement. A further direct durability run repeated the same check. The
   final read-only gate reports a matching build and image
   identity, one active/running/ready replica, and the expected
   `sf-accessible-explanation-checkin-data` share.

2. **200% mobile text resize.** On the candidate, a 390px `/privacy` visit
   with the root font size set to 32px measured `clientWidth: 390`,
   `scrollWidth: 551`, and `navRight: 550.36`. The header had a fixed mobile
   height and a non-wrapping navigation row. The mobile header now has an
   automatic minimum height and wrapping navigation. Every primary action
   remains visible; none is hidden or moved offscreen. The same live check now
   measures `clientWidth: 390`, `scrollWidth: 390`, `headerRight: 390`, and
   `navRight: 374`.

## Regression coverage

- `frontend/tests/app.spec.ts` adds the 390px regression. It sets the root
  font size to 32px on `/privacy`, requires document/header/navigation bounds
  to stay inside the viewport, and checks that Privacy and the theme control
  remain visible.
- `scripts/test-durable-deploy.sh` exercises the public deployment command
  against the unsafe 1–3-replica template and requires the patch to converge
  to the Azure File mount and one replica.
- `scripts/test-live-topology.sh` rejects the exact multi-replica/unmounted
  topology and accepts only one healthy mounted replica. The production claim
  additionally executes `npm run verify:live-topology`.

## Verification evidence

| Check | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages; 0 reported vulnerabilities |
| `npm test` | PASS — TypeScript, 5 Vitest tests, 13 Rust tests, durable deployment and topology fixtures |
| `npm run build` | PASS — JS 38.93 kB raw / 12.43 kB gzip; CSS 19.42 kB raw / 5.19 kB gzip |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| Container identity/runtime/deployment tests | PASS — non-root runtime, build identity, one-replica Azure File policy |
| `npm run test:all-claims` | PASS — all 25 declared claim commands, including the real live topology claim |
| `npm run test:e2e` | PASS — complete desktop and 390px Chromium app and claim suites |
| `npm run verify:live-topology` | PASS — current revision, one active/ready/running replica, `/app/data` Azure File mount, live SHA matches |
| `AUDIT_EVIDENCE_PREFIX=repair-11 npm run audit:live` | PASS — seven routes/light and dark themes, 200% text, axe, keyboard route focus, demo reset/isolation/offline reload, privacy boundary, workflow, voice limits, checkout, headers, and no console errors |
| Lighthouse 12.8.2 mobile | PASS — Performance 99, Accessibility 100, Best Practices 100, SEO 100; LCP 1153 ms; CLS 0 |

The live audit records its exact route, accessibility, offline, privacy, and
workflow results in
[`repair-11-live-check.json`](evidence/repair-11-live-check.json). Screenshots
are `repair-11-live-demo-mobile.png` and `repair-11-live-404-mobile.png`.
Lighthouse evidence is
[`repair-11-lighthouse-mobile.json`](evidence/repair-11-lighthouse-mobile.json).

## Run and deploy

```sh
npm ci
npm test
npm run build
npm run test:all-claims
npm run test:e2e
npm run verify:live-topology
AUDIT_EVIDENCE_PREFIX=repair-11 npm run audit:live
npm run deploy
```

`npm run deploy` is the required Container Apps command. It builds the same
container, provisions or reuses the product Azure File share, pins SQLite to
one replica, validates the effective control plane, and proves a record
survives a revision replacement.

## Known gap

Docker and Podman CLIs are not installed in this worker. The Dockerfile's
build-identity and non-root runtime contracts passed locally, and the actual
ACR build plus deployed container passed the live identity, topology, and
durability checks.
