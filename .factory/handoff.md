# Handoff — perfection loop round 3

## What changed

Closed every finding from `.factory/review-1.md`, `review-2.md`, and
`review-3.md`. The full mapping is in `.factory/polish-3.md`.

The $39 Classroom Plus product is now registered in the live Sociobot catalog.
Its public checkout endpoint returns a 303 to an unpaid Dodo checkout session,
and the claim test verifies that live handoff before using its navigation
fixture. Playwright is pinned to 1.58.2 and the committed lockfile works with
`npm ci` in a fresh clone.

Mobile targets are at least 44 × 44 pixels on every public route and the real
404. The shared footer now includes builder and version details. The product's
existing doorway/classroom identity, responsive layout, route metadata, legal
links, focus transfer, offline sample, and demo isolation remain intact.

The first live cold audit found one deployment-only issue not visible in the
review: Rust's standard file copy tried to apply POSIX permissions to the
Azure Files SMB snapshot. That made real check-in creation return 500 under
the non-root user. Snapshot writes now stream and sync file bytes without a
chmod. The live create, student submission, teacher review, and saved-review
reload all pass on the mounted production volume.

## How to run and verify

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:claims
npm run test:all-claims
npm run test:runtime-policy
npm run test:container-identity
npm run test:deploy-helper
cargo fmt --check
cargo clippy --all-targets --locked -- -D warnings
npm run audit:live
```

Every `test` command in `.factory/claims.json` was also executed individually
from clean clone `/tmp/tmp.kdTNlYkusU/repo`; all 18 passed.

## Exact evidence

- `npm test`: 4 frontend unit tests, 11 Rust tests, and deployment policy pass.
- `npm run test:e2e`: 36 passed, 8 intentional mobile/single-fixture skips.
- `npm run test:claims`: 21 passed, 7 intentional mobile/single-fixture skips.
- Production bundle: 12.47 kB gzip JavaScript and 5.16 kB gzip CSS.
- Live URL: <https://accessible-explanation-checkin.sociobot.in>.
- Live audit source build: `39e378fa601ef845cdd8e560784697d966c826a7`.
- Live audit JSON: `.factory/evidence/polish-3-live-check.json`.
- Home and demo verification: `.factory/evidence/polish-3-live-home/` and
  `.factory/evidence/polish-3-live-demo/`.
- Mobile demo and 404 screenshots:
  `.factory/evidence/polish-3-live-demo-cold-mobile.png` and
  `.factory/evidence/polish-3-live-404-mobile.png`.
- Lighthouse JSON: `.factory/evidence/polish-3-live-lighthouse-mobile.json`.
- Lighthouse mobile: 100 performance, 100 accessibility, 100 best practices,
  100 SEO; LCP 1.05 s, TBT 13 ms, CLS 0.
- Live audit checked all seven public/error routes in light and dark modes:
  zero serious/critical axe findings, zero undersized targets, no horizontal
  overflow at 100% or 200% text, correct metadata/statuses, and no unexpected
  console errors.
- Live demo: three sample responses, `demo:`-only storage, reset restored the
  seed, no API write, and an offline reload succeeded.
- Live checkout: catalog price 3900 USD minor units; endpoint returned 303 to
  `checkout.dodopayments.com` without submitting payment.
- Deployment: `scripts/deploy-durable-container.sh` used the factory container
  deployer, mounted Azure Files at `/app/data`, and pinned replicas to one.

## Known gaps and next steps

None. No finding of any severity remains open. The live audit intentionally
created synthetic “Live release verification” records; they contain no person
or classroom data and may expire with normal product retention.
