# Repair 17 — candidate image identity

- Work order: `accessible-explanation-checkin-repair-17`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Implementation SHA: `8f2956bf5bafed7b9d0b27b53b92bf9cf3abd6bd`
- Verified: 2026-09-05 UTC
- Result: **PASS**

## Finding and cause

Verification 20 correctly blocked release. The repository already distinguished
shipped product commits from later report and Graphify commits, but the durable
deployment wrapper passed the repository working tree to the fleet helper. The
helper therefore built and tagged raw repository `HEAD` while the topology gate
expected the resolved implementation commit. A later report-only deployment
could publish an image whose tag, health response, and embedded build identity
did not share one source commit.

## Repair

- `scripts/deploy-durable-container.sh` now resolves and validates the product
  candidate, creates a clean detached clone at that exact commit, and gives that
  clone to the fleet deployment helper. Topology and durability checks use the
  same resolved SHA.
- The deployment regression fixture adds a report-only commit and proves the
  helper still receives the prior clean product candidate.
- `.dockerignore` excludes `graphify-out` from build context.
- `scripts/verify-live-topology.sh` now verifies immutable ACR image digests by
  resolving the candidate tag in this product's repository and comparing its
  digest with the running revision. Tagged-image verification remains covered.
- The live-topology fixture covers both a digest mismatch and a matching
  immutable digest.
- The live audit now records the cold phone and desktop first screens and
  deletes every real check-in it creates after verifying the workflow.

## Clean-checkout gates

A clean detached clone of the pushed implementation commit was made at
`/tmp/aec-repair17-clean.Fs3tyt/repo`. Its `git status --short` remained empty.

- `npm ci`: 86 packages installed; 0 vulnerabilities.
- `npm run test:all-claims`: all 27 declared claim commands passed.
- `npm test`: 5 Vitest tests, 18 Rust tests, and all deployment fixtures passed.
- `npm run build`: `dist/` produced; JS 40.34 KB raw / 12.76 KB gzip and CSS
  19.47 KB raw / 5.20 KB gzip.
- `cargo fmt --all -- --check`: passed.
- `cargo clippy --all-targets --locked -- -D warnings`: passed.
- `cargo build --release --locked`: passed.
- `npm run test:e2e`: desktop and 390 px mobile shards passed, with only the
  intentional project-specific skips.

## Deployment and live result

- Image: `sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54@sha256:ee3d2502c582b78f2a6c56b26930bf80da33c9afaafe71fefa85dc1296a9d863`
- Revision: `sf-accessible-explanation-9c1a54--0000150`
- `/health` build SHA: exact implementation SHA `8f2956bf…`.
- Topology: one active, running, ready replica; min/max 1/1; Healthy;
  RunningAtMaxScale; the fleet-created Azure Files share is mounted at `/data`.
- Deployment replacement check: student, review, and receipt reads were 24/24
  before and after revision replacement; a new submission and saved review also
  survived.
- Fresh live phone and desktop browsers showed the job, teacher audience, and
  `Try it with sample data` action before scrolling. The demo opened three
  realistic explanations, retained its sample-data banner, reset to the shipped
  values, discarded demo keys on exit, made no API writes, and reloaded offline.
- The real create, submit, receipt, review, reload, voice boundary, voice delete,
  and full delete paths passed. Audit-created records were deleted afterward.
- Seven public routes passed expected statuses, route titles, metadata, links,
  200% text, touch targets, reduced motion, focus restoration, and console
  checks. The designed missing page returned the expected HTTP 404.
- Axe found 0 serious or critical issues across all seven routes in light and
  dark themes. Factory `verify-url.sh` passed with one h1, `lang=en`, main,
  complete alt text, labeled buttons, and no console errors.
- A 150-request same-client burst produced 120 HTTP 404 and 30 HTTP 429
  responses. Every 429 included `Retry-After`.
- Lighthouse 12.8.2 mobile: Performance 100, Accessibility 100, Best Practices
  100, SEO 100; LCP 1.128 s, total blocking time 13 ms, CLS 0, total transfer
  39,470 bytes, and no third-party resources.

Evidence is under [evidence](evidence), including the
[live audit](evidence/repair-17-live-check.json),
[topology](evidence/repair-17-live-topology.json),
[rate limit](evidence/repair-17-rate-limit.json),
[Lighthouse report](evidence/repair-17-lighthouse-mobile.json), and the
[factory URL check](evidence/repair-17-url/verify.json).

## Earlier finding disposition

The complete verification 1–20, review 1–8, and polish 1–8 history was read
before this repair. The round-eight finding map remains in
[polish-8.md](polish-8.md). All earlier functional, accessibility, privacy,
copy, billing, demo, persistence, rate-limit, and topology findings remain
closed under the clean and live regressions above. Verification 20's sole new
blocker is closed by the exact-candidate build and immutable-digest proof.

## Known gaps

None found. The optional Classroom Plus offer remains registered and live at
$39 once; the free classroom workflow remains complete without a license.
