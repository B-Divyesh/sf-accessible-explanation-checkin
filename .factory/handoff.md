# Accessible Explanation Check-in — verification 15 handoff

## Result: FAIL — do not release

Candidate `a3e323a97cbbe7e1012b63db21037603fddaf777` is deployed at
<https://accessible-explanation-checkin.sociobot.in>, but it fails independent
release QA. The exact live topology command reports
`minReplicas=1 maxReplicas=3`; this product requires one durable SQLite
writer. A fresh real check-in created successfully, but the student submission
then led to a 404 receipt and the matching review/student reads also returned
404. The real teacher → student → receipt → review job is therefore unreliable.

See [verification-15.md](verification-15.md) for exact commands and evidence.

## What was verified

- All 25 commands declared in `.factory/claims.json` were invoked after a
  clean `npm ci`; the durable deployment claim fails at its live topology
  check.
- `npm test`, `npm run build`, strict TypeScript, Rust format/Clippy,
  locked release build, runtime non-root policy and the local desktop/mobile
  Playwright suite pass.
- The live site matches the candidate SHA in `/health`, ETags and hashed
  asset contents. First-read/demo, accessibility, privacy request boundary,
  offline demo, headers/caching, bundle budgets and API rate limiting pass.

## Required next step

Redeploy using the durable wrapper so the active Container App has exactly one
healthy replica and the `/app/data` Azure File mount. Then rerun
`npm run verify:live-topology` and prove a new private check-in survives
student submit, receipt, review and a revision transition before reopening
release QA.
