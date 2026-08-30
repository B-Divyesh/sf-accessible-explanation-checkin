# Accessible Explanation Check-in — repair 13 handoff

## Result: PASS — repaired and deployed

The verification-15 release blocker is repaired. Live service:
<https://accessible-explanation-checkin.sociobot.in>.

## Exact live durability evidence

The repair was deployed from `726120189aaa25c44f784b3e2c4205991db788b7`.
The live deployment gate passed on 2026-08-30:

- Container App: `sf-accessible-explanation-9c1a54`
- Verified revision: `sf-accessible-explanation-9c1a54--0000125`
- Image: `sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:726120189aaa`
- Azure Files storage/share: `aec-accessible-explanati-9c1a54` /
  `sf-accessible-explanation-checkin-data` (read/write)
- Volume/mount: `data` → `/data`
- Scale: `minReplicas=1`, `maxReplicas=1`; exactly one active, running, ready,
  healthy revision/replica.

`scripts/verify-live-durable-workflow.sh` created a fresh private check-in,
read its student and review links 24 times, submitted it (`201`), saved the
teacher review, read the receipt 24 times, forced a Container Apps revision,
then repeated all 24 student/review/receipt reads. Every read returned `200`;
the result reported `submission_and_review_persisted: true` after the new
revision.

## Reproduction and root causes

Before changes, the topology gate against candidate
`a3e323a97cbbe7e1012b63db21037603fddaf777` failed with:

```text
expected minReplicas=maxReplicas=1; observed minReplicas=1 maxReplicas=3
```

The template had no Azure File volume. A live create returned `201`, but
independent replicas returned `404` for the private student, receipt, and
review state.

The first mount/one-replica repair exposed a second production failure: direct
SQLite writes on Azure Files SMB waited 30 seconds then failed with `database is
locked`. The final design runs SQLite locally in the one replica, copies its
committed single-file snapshot to `/data/checkins.db` after every mutation, and
restores it before the next revision. Voice uploads remain under `/data`. This
avoids SMB byte-range locks while retaining private state on the durable share.

The deploy wrapper clears the inherited `WO_DATA_DIR` only for the generic
factory helper, preventing its invalid overlong storage name. It then attaches
the already registered product storage resource and fails closed unless both
the topology and live workflow pass.

## Changes and regression coverage

- `34360b3`, `a5a1ced`, `123311a`, `d3f7f4f`, `91d8270`, and `7261201` repair
  durable state, Docker runtime setup, one-replica deployment, storage naming,
  SMB-safe snapshots, and test database isolation.
- `scripts/test-durable-deploy.sh` reproduces verifier 15's `1 → 3` replica
  regression after a simulated workflow revision and requires the `/data`
  Azure File mount patch to reject it.
- `scripts/test-live-durable-workflow.sh` validates private student/review/
  receipt state through a replacement revision.
- `db::tests::durable_snapshot_restores_sqlite_records_after_a_fresh_runtime`
  proves a saved check-in is restored from durable storage in a fresh runtime.
- `tests::database_override_does_not_restore_or_replace_the_default_snapshot`
  keeps test/maintenance database overrides isolated without explicit
  `PERSISTENCE_DIR`.
- `scripts/test-nonroot-runtime.sh` proves the release binary writes both its
  local database and `/data` snapshot as an unprivileged user.

## Verification completed

From a clean `npm ci`:

- `npm test` — TypeScript 5 tests, Rust 17 tests, and all deployment/workflow
  fixtures passed.
- `npm run test:e2e` — desktop and 390px mobile suites passed; desktop app
  checks had 9 passing and 2 intentional mobile-only skips.
- `npm run test:runtime-policy`, `npm run test:container-identity`, strict
  `cargo fmt --check`, `cargo clippy --all-targets --locked -- -D warnings`,
  locked release build, and `npm run build` passed. Production assets are
  12.43 kB gzip JavaScript and 5.19 kB gzip CSS.
- `npm run test:all-claims` completed all 25 declared claim commands.
- `npm run verify:live-topology` passed with the exact live app, SHA, `/data`
  mount, share, health, ready revision, and one-replica values above.
- `/opt/fleet/lib/verify-url.sh` passed: 604 ms load, no console errors,
  title/lang/one h1/main present, no missing alt text, and no unlabeled
  buttons. Evidence: `.factory/evidence/repair-13-verify-url/`.
- The live Playwright + axe audit passed all seven public routes in light and
  dark themes with zero serious/critical findings, 44px targets, no 200% text
  overflow, no console errors, working focus announcements, offline demo,
  demo isolation, same-origin private workflow requests, response headers, and
  the $39 checkout redirect. Evidence:
  `.factory/evidence/repair-13-live-check.json`.
- Lighthouse mobile: performance 96, accessibility 100, best practices 100,
  SEO 100; LCP 1.2 s and CLS 0. The standalone Selenium axe CLI could not
  start Chrome in this worker; the passing live audit uses the installed
  Playwright Chromium and `@axe-core/playwright`.

## Deploy / operate

Run `npm run deploy`. It builds the root Dockerfile, deploys on port 8080,
mounts the factory-registered Azure File share at `/data`, enforces one SQLite
replica, and runs the replacement-revision durability gate. `npm run
verify:live-topology` is a read-only current-build topology check.

No known release gaps remain. The unrelated pre-existing `graphify-out/`
working-tree changes were not modified or committed.
