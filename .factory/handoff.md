# Accessible Explanation Check-in — repair 14 handoff

## Result

The failed candidate was replayed through the product deployment command and
the durable SQLite deployment contract is now guarded against mount-path drift.
The final release command is `npm run deploy`; it deploys only
`sf-accessible-explanation-9c1a54` and retains the required `/data` mount.

## Reproduction and root cause

The candidate `d9f80ed769661554efb76c22aa8a5d9a820813a5` had not reached the
running Container App. Before replaying the deploy, its exact identity check
failed with:

```text
image sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:4e123ab5ecde does not identify build d9f80ed76966
```

The prescribed `npm run deploy` command rebuilt and deployed that candidate;
the resulting live revision was `sf-accessible-explanation-9c1a54--0000129`.
It passed the one-replica `/data` topology gate and the real replacement-
revision workflow. The replay established that this was a missed/stale release
rather than a Docker image-build failure.

The historical deployment failure class was the generic helper's stateless
template (`minReplicas=1`, `maxReplicas=3`, no Azure Files mount), which can
split private SQLite records across replicas. The durable wrapper already
clears the inherited `WO_DATA_DIR` before the generic helper, then attaches the
factory-registered product storage and pins one replica. This repair adds an
early, explicit guard: the stateful service accepts only
`DEPLOY_DATA_DIR=/data`. A mismatched inherited path now fails before the
generic helper can publish a stateless or incorrectly mounted revision.

## Changes

- `scripts/deploy-durable-container.sh` rejects any durable mount path other
  than `/data`.
- `scripts/test-durable-deploy.sh` adds a focused regression test that injects
  `DEPLOY_DATA_DIR=/app/data`, requires the clear error, and proves the generic
  deployment helper was not invoked.

## Verification

- Clean build: `npm ci && npm run build` passed. The built frontend is
  12.43 kB gzip JavaScript and 5.19 kB gzip CSS.
- `npm test` passed: 5 TypeScript/Vitest tests, 17 Rust tests, and durable
  deployment, revision-workflow, and topology fixtures.
- `cargo fmt --all -- --check`, `cargo clippy --all-targets --locked -- -D
  warnings`, `cargo build --release --locked`, `npm run
  test:container-identity`, `npm run test:runtime-policy`, and `npm run
  test:deploy-helper` all passed.
- `npm run test:e2e` passed its desktop and 390px mobile suites, including
  keyboard flow, mobile controls, 200% text resize, and the real
  student-to-review flow.
- `npm run test:all-claims` completed all 25 declared claims, including demo
  isolation/reset/exit, offline reload, privacy request boundaries, recorded
  billing verdicts, and the live durable-deployment claim.
- `/opt/fleet/lib/verify-url.sh` passed for the live root (638 ms; title,
  `lang=en`, one `h1`, `main`, image alt text, named buttons, and no console
  errors). Evidence: `.factory/evidence/repair-14-verify-url/`.
- The live Playwright + Axe audit passed all seven public routes in light and
  dark themes with zero serious/critical findings. It also proved 44px targets,
  200% text resize, keyboard focus/announcements, offline demo reload,
  demo isolation, same-origin workflow requests, private workflow persistence,
  voice limits/deletion, security headers, and the $39 Sociobot/Dodo redirect.
  Evidence: `.factory/evidence/repair-14-live-check.json`.
- Fresh mobile Lighthouse reported Performance 100, Accessibility 100, Best
  Practices 100, SEO 100; LCP 1126 ms and CLS 0. Evidence:
  `.factory/evidence/repair-14-lighthouse-mobile.json`. Lighthouse emitted a
  post-results headless-tab crash warning, but wrote the complete scored report;
  the independent Playwright audit above passed without browser errors.
- Live identity/topology for the replayed candidate reported image
  `sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:d9f80ed76966`,
  one active healthy revision and replica, and the read/write product Azure
  File share mounted at `/data`.

## Deploy and operate

Run `npm run deploy`. It uses the root multi-stage Dockerfile, serves on port
8080, mounts the factory-registered `sf-accessible-explanation-checkin-data`
share at `/data`, pins one SQLite writer, then checks private links, a
submission, a receipt, and teacher review across a replacement revision.
`npm run verify:live-topology` is the read-only live identity and topology
check.

No known product gaps remain.
