# Handoff — polish 1

## Delivered

This repair closes every item in `.factory/review-1.md` and the earlier
verification records. The landing now names the teacher job plainly. `/demo`
and `?demo=1` open an isolated, populated teacher review with reset and
start-real controls. Demo edits are stored only under the `demo:` localStorage
namespace and make no API requests.

The repair also adds claim inventory and tagged browser proof, route focus and
announcements, per-route canonical/social metadata, original 1200×630 social
art, a 404 response with HTTP 404, plain-language copy audit, responsive demo
layout, and a non-root runtime container user. The rate limiter now covers the
API rather than static page navigation.

## Verification

Run from the repository root:

```sh
npm ci
npm test
npm run build
npm run test:e2e
cargo fmt --all -- --check
cargo clippy --all-targets --locked -- -D warnings
cargo build --release --locked
npm run test:container-identity
npm run test:deploy-helper
npm run test:deployment-policy
```

Current local evidence:

- `npm test`: passed; 4 TypeScript and 7 Rust tests.
- `npm run build`: passed; 38.70 KB JavaScript (12.52 KB gzip) and 19.08 KB
  CSS (5.13 KB gzip).
- `npm run test:e2e`: passed; 29 browser checks across desktop and 390 px
  mobile, with one intentional desktop-only skip. It includes axe serious and
  critical checks, metadata/focus/404 coverage, the teacher/student flow, and
  all claim tests.
- strict formatting, Clippy, locked release build, durable-deployment policy,
  deterministic deploy-helper, and non-root container identity checks passed.
- Local release smoke on port 18080: `/health` returned 200 and
  `/no-such-page` returned 404. Screenshots are in `.factory/evidence/`.

Every claim test command in `.factory/claims.json` is intended to run from a
fresh browser context at `/demo`. Demo operation is documented in
`.factory/demo.md`.

## Deployment

Deployment class remains a Container App. Use:

```sh
scripts/deploy-durable-container.sh accessible-explanation-checkin /work/repo Dockerfile 8080
```

The helper mounts durable `/app/data` and pins SQLite to one replica. The
runtime image starts on `PORT` with no required configuration and runs as the
non-root `checkin` user. Docker is not installed in this worker, so image UID
execution is verified through source policy and must also be observed in the
factory container build/deploy log.

## Known gaps

None in the review scope. The final live deployment check and its exact commit
are appended after the work-order deployment completes.
