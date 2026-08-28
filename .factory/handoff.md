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
- `npm run test:e2e`: passed; 31 browser checks across desktop and 390 px
  mobile, with one intentional desktop-only skip. It includes axe serious and
  critical checks, metadata/focus/404 coverage, the teacher/student flow, and
  all claim tests.
- strict formatting, Clippy, locked release build, durable-deployment policy,
  deterministic deploy-helper, and non-root container identity checks passed.
- Local release smoke on port 18080: `/health` returned 200 and
  `/no-such-page` returned 404. Screenshots are in `.factory/evidence/`.

Every claim test command in `.factory/claims.json` runs from a fresh browser
context at `/demo`. A clean clone of deployed code commit
`08f98714586c017a5022acc48fe48eaa4afb2a9a` ran `npm ci`, `npm run build`, and
`npm run test:claims`: **18 passed**.
Demo operation is documented in `.factory/demo.md`.

## Deployment

Deployment class remains a Container App. Use:

```sh
scripts/deploy-durable-container.sh accessible-explanation-checkin /work/repo Dockerfile 8080
```

The helper mounts durable `/app/data` and pins SQLite to one replica. The
runtime image starts on `PORT` with no required configuration and runs as the
non-root `checkin` user. Docker is not installed in this worker, so image UID
execution is verified through source policy and the successful cloud build.

## Known gaps

None in the review scope.

## Final deployed evidence

The final deployed code commit is `08f98714586c017a5022acc48fe48eaa4afb2a9a`.
The Container App revision `sf-accessible-explanation-9c1a54--0000017` is
healthy, has 100% traffic, uses its Azure File mount at `/app/data`, and is
pinned to one replica. Cold `GET /health` at the public URL returned that exact
SHA. `GET /no-such-page` returned HTTP 404. The factory `verify-url.sh` check
on `/demo` passed in 540 ms with zero console errors, one h1, one main, `lang`
set, and no missing image alt or unlabelled button. A live 390 px Axe audit of
`/?demo=1` returned zero serious or critical violations. It observed only the
product origin during the demo load. Final artifacts are in
`.factory/evidence/live-verify-final/`.
