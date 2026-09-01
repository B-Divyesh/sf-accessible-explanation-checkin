# Accessible Explanation Check-in — repair 16 handoff

## Result

The verification-16 release blocker is repaired, committed, pushed, and live.
Commit `d3ce87c0940af8695680137db646c749b5449e93` is deployed at
<https://accessible-explanation-checkin.sociobot.in>. The product remains a
Rust/axum + Vite container application, with SQLite state persisted through
the product's `/data` Azure Files mount.

## Reproduction and repair

Before changing code, I cloned the verifier candidate under
`/tmp/aec-repro-xH10WC/clone-under-a-different-path`, ran `npm ci`, then ran
`npm run test:deployment-policy`. It failed with exit status `1`, reproducing
verification 16 exactly. The old deployment wrapper defaulted its repository
argument to `/work/repo`, so `npm run deploy` passed the wrong build context
outside the factory workspace.

`scripts/deploy-durable-container.sh` now derives its default repository from
its own `scripts/` directory using `BASH_SOURCE[0]` and physical paths. An
explicit positional repository argument still overrides that default.

`scripts/test-durable-deploy.sh` now:

- reports expected and actual fixture values on a mismatch instead of failing
  silently;
- invokes the package `deploy` command from a fresh relocated clone, with no
  repository argument; and
- asserts that the generic deployment helper receives that clone's path,
  while retaining the existing `/data`, one-replica, no-storage-credential,
  and post-revision durability regressions.

## Verification

All commands below passed.

- Root clean install and aggregate gate: `npm ci --no-audit --no-fund && npm test`
  (5 TypeScript/Vitest tests, 17 Rust tests, deployment, durability, and
  topology fixtures).
- Production quality checks: `npm run build`, `cargo fmt --all -- --check`,
  `cargo clippy --all-targets --locked -- -D warnings`, `cargo build --release
  --locked`, `npm run test:container-identity`, and `npm run test:runtime-policy`.
  The production bundle is 12.43 kB gzip JavaScript and 5.19 kB gzip CSS.
- Browser coverage: `npm run test:e2e` passed for desktop and 390 px mobile,
  including keyboard flow, demo isolation/reset/exit, offline reload,
  privacy request boundaries, response limits, voice handling, student and
  teacher workflow, billing fixture, and serious/critical Axe checks.
- Required independent-path proof: a clean GitHub clone at
  `/tmp/aec-clean-proof-GRyrIw/repository-outside-workspace` was confirmed
  clean at `d3ce87c0940af8695680137db646c749b5449e93`; `npm ci` installed 86
  locked packages; `npm run test:deployment-policy` and the complete `npm
  test` both passed there. `npm run test:all-claims` then completed all 25
  declared claims from that same clone, including the exact compound
  `durable-deployment-policy` claim.
- Live deployment identity and policy: `/health` returned build SHA
  `d3ce87c0940af8695680137db646c749b5449e93`; `npm run
  verify:live-topology` passed for revision
  `sf-accessible-explanation-9c1a54--0000136`, image tag `d3ce87c0940a`, one
  active/running/ready replica, and `data` mounted at `/data` from
  `sf-accessible-explanation-checkin-data`.
- Live URL verification: `/opt/fleet/lib/verify-url.sh` passed in 617 ms with
  no console errors, the correct title/lang, one h1, main landmark, and no
  missing image alt text. See
  [repair-16-verify-url](evidence/repair-16-verify-url/verify.json).
- Live accessibility: the repository's Playwright Axe integration checked
  `/`, `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, and the 404 at
  390 px in light and dark themes; all 14 scans had zero serious or critical
  findings. The standalone Axe CLI could not locate a system Chrome binary in
  this container, so Playwright's preinstalled Chromium was used instead.
- Live mobile Lighthouse passed with Performance 100, Accessibility 100, Best
  Practices 100, and SEO 100; FCP 0.9 s, LCP 1.1 s, TBT 30 ms, CLS 0. See
  [repair-16-lighthouse-mobile.json](evidence/repair-16-lighthouse-mobile.json).

## Deploy and operate

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
npm run deploy
```

`npm run deploy` derives its source checkout from the installed deployment
script, so it is safe to run from any cloned repository path. It targets only
this product, deploys on `PORT=8080`, requires the `/data` durable mount, and
verifies live identity, one-replica topology, and a private-record durability
workflow before reporting success.

## Known gaps

None in the product. The standalone Axe CLI is not usable in this worker
because it requires a system Chrome binary; the equivalent Playwright Axe
audit ran against the preinstalled browser and passed.
