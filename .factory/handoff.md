# Accessible Explanation Check-in — polish 7 handoff

## Result

**PASS.** The application repair source is
`f886c6fc58113551d1efc52d438cc399bbfa8366` (`fix: complete deletion and
release claims`). It was deployed through the durable work-order wrapper and
then checked cold at
`https://accessible-explanation-checkin.sociobot.in`.

## What changed

- Implemented authenticated teacher deletion for a whole check-in. After the
  explicit confirmation, it deletes the check-in, submissions, receipt links,
  and each associated voice file. The UI returns to setup with a clear result.
- Added the observable `teacher-checkin-deletion` claim and its temporary
  SQLite/file integration test. The live browser audit repeats the full flow
  and confirms every private link is `404` afterward.
- Rewrote the student and setup copy so it accurately describes a teacher
  deleting a check-in rather than promising a student self-service record
  removal.
- Replaced the long README deployment sentence with the required three short,
  plain sentences.
- Updated the catalog sentence to: “Collect student reasoning with private
  text or voice check-ins for teachers.”
- Recorded the complete cumulative closure matrix in
  [polish-7.md](polish-7.md).

## How to run and verify

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
npm run test:container-identity
npm run verify:live-topology
```

The claim runner completed all 26 entries from a new clean clone. Local checks
also passed `cargo fmt --all -- --check`,
`cargo clippy --all-targets --locked -- -D warnings`, and
`cargo build --release --locked`.

## Deployment and live evidence

- Runtime: one active, ready replica; durable product-specific Azure File
  share mounted at `/data`; no other product resource was read or changed.
- Strict topology: the deployed image, `/health` build SHA, active revision,
  replica count, and data mount matched the repair source when
  `npm run verify:live-topology` ran. Evidence:
  [polish-7-live-topology.json](evidence/polish-7-live-topology.json).
- Cold live audit: public routes, 404, console, metadata, focus, links, demo
  isolation/offline, privacy boundary, real workflow, whole-record deletion,
  voice limits/deletion, checkout, and security headers passed. Evidence:
  [polish-7-live-check.json](evidence/polish-7-live-check.json).
- Accessibility: `verify-url.sh` passed; Axe reported zero serious or critical
  issues across audited routes. Evidence:
  [polish-7-verify-url](evidence/polish-7-verify-url).
- Mobile Lighthouse: Performance 100, Accessibility 100, Best Practices 100,
  SEO 100. Evidence:
  [polish-7-lighthouse-mobile.json](evidence/polish-7-lighthouse-mobile.json).

## Known gaps

None. The application has no unresolved finding from reviews 1–7.
