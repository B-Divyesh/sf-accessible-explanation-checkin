# Handoff — Polish 4 repair

## What changed

- Added **Privacy** to the four-link primary navigation in the SPA shell and
  the real static HTTP 404 page.
- Added a browser regression that requires the primary Privacy link on `/`,
  `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, and `/no-such-page`.
- Strengthened the non-root runtime claim so a clean-clone test stages the
  release app where UID 65534 can read it, then proves the live server wrote a
  UID-65534 durable snapshot. This removes a `/proc` wrapper-process race.
- Updated the live audit to assert visible Privacy navigation and save Polish 4
  screenshots and machine-readable output.
- Updated the verb-first catalog description and wrote the complete cumulative
  finding map in `.factory/polish-4.md`.

## Repair source and local evidence

Product repair source: `0400d23952a7f91447d5b1a51f68f732c25ef242` on `main`.
The clean clone was `/tmp/accessible-explanation-checkin-polish4-final.L3vqGa`.

From that fresh clone, after `npm ci` (86 packages, 0 vulnerabilities):

- `npm test` passed: 4 frontend unit tests, 11 Rust tests, and deployment policy.
- `npm run build` passed: `dist/`; 12.48 kB gzip JavaScript and 5.16 kB gzip CSS.
- `npm run test:e2e` passed: 38 passed, 8 intentional single-fixture/mobile skips.
- `npm run test:all-claims` passed every one of the 18 commands in
  `.factory/claims.json`, including offline reload, request-boundary privacy,
  workflow, retention cleanup, checkout, non-root runtime, and deployment.
- `cargo fmt --check` and `cargo clippy --all-targets --locked -- -D warnings` passed.

## Deployment and live recheck

Deployed through `scripts/deploy-durable-container.sh` to
`https://accessible-explanation-checkin.sociobot.in` after the repair push.
The final cold live audit, screenshots, live build SHA, route checks, mobile
checks, light/dark axe checks, offline demo check, workflow, checkout, and
headers are recorded in `.factory/evidence/polish-4-live-check.json`,
`.factory/evidence/polish-4-live-demo-cold-mobile.png`, and
`.factory/evidence/polish-4-live-404-mobile.png`.

## Known gaps and next steps

None. All findings F-1-1 through F-4-1 are closed in `.factory/polish-4.md`.
