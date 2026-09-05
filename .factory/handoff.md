# Accessible Explanation Check-in — repair 17 handoff

## Result

**PASS — release blocker closed.** The live image, immutable ACR digest, health
response, and mandatory topology claim now identify the same implementation.

- Implementation SHA: `8f2956bf5bafed7b9d0b27b53b92bf9cf3abd6bd`
- Evidence/documentation SHA: `a200f12fc26bd876f198d0e220f72433ef2e8d41`
- Live revision: `sf-accessible-explanation-9c1a54--0000150`
- Image digest: `sha256:ee3d2502c582b78f2a6c56b26930bf80da33c9afaafe71fefa85dc1296a9d863`

This handoff update is a later report-only commit. It does not require another
product image; `scripts/resolve-product-candidate.sh` still resolves the exact
implementation SHA above.

## What changed

The deployment wrapper previously resolved the right product commit for its
checks but gave raw repository `HEAD` to the image builder. It now builds from
a clean detached clone of the resolved candidate and uses that SHA throughout
deployment verification. Regression tests cover a later report-only commit.

The live topology gate now supports the fleet helper's immutable image form. It
resolves this product candidate's ACR tag to a digest and compares that digest
with the running revision. A digest mismatch and a matching digest are both
covered. `graphify-out` is excluded from the Docker build context.

The live audit now saves cold phone and desktop first screens and removes every
real verification check-in after testing it. Product behavior and scope were
otherwise preserved.

Full finding and evidence details are in [repair-17.md](repair-17.md).

## Verification

From a clean detached clone of the pushed implementation SHA:

- `npm ci`: passed, 0 vulnerabilities.
- `npm run test:all-claims`: all 27 declared commands passed.
- `npm test`: passed, including 5 Vitest and 18 Rust tests.
- `npm run build`: passed and produced `dist/`; initial JS is 12.76 KB gzip and
  CSS is 5.20 KB gzip.
- `cargo fmt --all -- --check`: passed.
- `cargo clippy --all-targets --locked -- -D warnings`: passed.
- `cargo build --release --locked`: passed.
- `npm run test:e2e`: desktop and 390 px mobile shards passed.

The durable deployment check observed 24/24 successful student, review, and
receipt reads before and after revision replacement. The saved response and
review remained present. The final topology is one healthy, active, running,
ready replica with min/max 1/1 and the fleet-created share mounted at `/data`.

Fresh live phone and desktop checks passed the first screen, sample demo,
reset, demo exit, offline reload, real workflow, deletion, invalid and boundary
paths, route titles, links, legal pages, expected 404, focus, reduced motion,
200% text, light/dark themes, privacy requests, headers, and console checks.
The real audit fixtures were deleted afterward.

Axe found no serious or critical issue on seven routes in both themes. Factory
`verify-url.sh` passed. A 150-request burst returned 30 HTTP 429 responses, and
every 429 included `Retry-After`.

Lighthouse 12.8.2 mobile scores were Performance 100, Accessibility 100, Best
Practices 100, and SEO 100. LCP was 1.128 s, total blocking time 13 ms, CLS 0,
and first-load transfer 39,470 bytes.

Primary evidence:

- [Live audit](evidence/repair-17-live-check.json)
- [Live topology](evidence/repair-17-live-topology.json)
- [Rate limit](evidence/repair-17-rate-limit.json)
- [Lighthouse](evidence/repair-17-lighthouse-mobile.json)
- [Factory URL check](evidence/repair-17-url/verify.json)
- [Phone first screen](evidence/repair-17-live-home-mobile.png)
- [Desktop first screen](evidence/repair-17-live-home-desktop.png)
- [Populated demo](evidence/repair-17-live-demo-mobile.png)

## Run locally

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
cargo fmt --all -- --check
cargo clippy --all-targets --locked -- -D warnings
cargo build --release --locked
```

Start the production server with `PORT=8080 cargo run --release --locked`.
Without `/data`, local durable files use the repository `data/` directory.

## Earlier findings and remaining work

All verification 1–20, review 1–8, and polish 1–8 records were inspected. The
round-eight disposition remains documented in [polish-8.md](polish-8.md). No
earlier finding regressed, and verification 20's image-identity blocker is now
closed.

No product gap remains from this work order. Classroom Plus remains the
registered $39 one-time offer; the free workflow remains complete. Public offer
metadata and the catalog description were copied to `/work/.evidence`.
