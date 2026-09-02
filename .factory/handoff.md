# Accessible Explanation Check-in — polish 8 handoff

## Result

**PASS.** The repaired candidate
`2182c924b7b2a2e1a9ed84f629538989a38aeacd` is deployed at
<https://accessible-explanation-checkin.sociobot.in>. The live health endpoint,
image tag, and topology gate all report that exact SHA.

## What changed

- Made live build verification resolve the last shipped product commit instead
  of documentation-only `HEAD`, with a regression test for reviewer commits.
- Added the public 1,200-character prompt limit to the claims manifest and
  tested 1,200 success, 1,201 rejection, visible recovery copy, and error focus.
- Standardized “judgment,” refreshed the copy audit, and changed the catalog
  line to: “Collect student reasoning through private text or voice check-ins
  for teachers.”
- Preserved the classroom editorial visual system, real routes, isolated demo,
  accessibility behavior, privacy boundaries, SQLite deployment, and original
  artifact class.

The complete finding-to-change map is in [polish-8.md](polish-8.md).

## How it was verified

- Clean clone of the pushed candidate: `npm ci`, `npm test`, `npm run build`,
  and `npm run test:all-claims` passed. All 27 claim commands completed.
- Full browser matrix: `npm run test:e2e` passed 52 tests with 12 intentional
  project skips across desktop and mobile shards.
- Rust quality: locked release build, formatting check, clippy with warnings
  denied, 18 backend tests, and non-root runtime policy passed.
- Cold live audit passed routing, titles, metadata, focus announcements, 404,
  legal links, mobile layout, 200% text, both themes, demo reset/disposal,
  offline reload, same-origin privacy, real create/submit/review/delete flows,
  voice limits/deletion, checkout, cache/security headers, and console checks.
- Axe reported zero serious or critical findings across all seven audited
  routes in light and dark themes. Factory `verify-url.sh` passed on home and
  the direct demo URL.
- A 150-request live API burst returned 120 normal 404 responses and 30 HTTP
  429 responses; every 429 included `Retry-After`.
- Mobile Lighthouse: Performance 98, Accessibility 100, Best Practices 100,
  SEO 100; LCP 1.3 s and CLS 0.
- Deployment revision `sf-accessible-explanation-9c1a54--0000146` is healthy
  with one active/running/ready replica, the product Azure File share mounted
  at `/data`, and exact build SHA `2182c924…`. Private student, review, and
  receipt links remained readable across revision replacement.

Evidence is under [.factory/evidence](evidence), especially
[live audit](evidence/polish-8-live-check.json),
[topology](evidence/polish-8-live-topology.json),
[durability](evidence/polish-8-live-durability.json), and
[Lighthouse](evidence/polish-8-lighthouse-mobile.json).

## Run locally

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
```

Start the production server with `PORT=8080 cargo run --release --locked`.
Without `/data`, local durable files use the repository `data/` directory.

## Known gaps and next steps

None. No round 1–8 finding is deferred.
