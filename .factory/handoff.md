# Polish 5 handoff — PASS

- Work order: `accessible-explanation-checkin-polish-5`
- Reviewed candidate: `976328637bdfe5cdec53afa4e4303882351ef760`
- Review base: `84766c5177e24971b5596de3eaa3f75e7e9f37d1`
- Deployed source: `5aa0519153e7c34d129d37b9aba69d359b960a33`
- Live revision: `sf-accessible-explanation-9c1a54--0000060`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Completed: 2026-08-29 UTC

## Outcome

All findings from reviews 1–5 are closed. The product keeps its original
blue-hour classroom and lit-doorway visual system. It remains a Vite frontend
served by the Rust axum and SQLite backend from one container.

Round 5 added complete claim coverage for stored fields, browser-only recent
links, and the recorded refund state. Unverified legal and infrastructure
promises were removed or rewritten as precise instructions. The documented
browser suite now runs in stable desktop and mobile shards.

Production now uses exactly one SQLite writer with the product's Azure File
share mounted at `/app/data`. The release gate proved the private workflow
before and after replacing the production revision.

The complete finding matrix is in `.factory/polish-5.md`.

## Clean-clone verification

Verified at `/tmp/aec-polish5-receipts.ATYgws/repo`, cloned from source commit
`5aa0519`:

- `npm ci`: pass; 86 packages, zero vulnerabilities.
- `npm test`: pass; TypeScript, 5 Vitest tests, 12 Rust tests, and both deployment fixtures.
- `npm run build`: pass; `dist/` produced.
- `npm run test:e2e`: pass; 43 passed and 9 intentional device skips.
- `npm run test:all-claims`: pass; all 21 entries ran independently.
- `cargo fmt --all -- --check`: pass.
- `cargo clippy --all-targets --locked -- -D warnings`: pass.
- `npm run test:container-identity`: pass.
- `npm run test:deploy-helper`: pass.

Production assets remain within budget:

- JavaScript: 38,568 bytes raw; 12,310 bytes gzip.
- CSS: 19,296 bytes raw; 5,160 bytes gzip.
- Mobile hero AVIF: 18,663 bytes.

Machine-readable results are in
`.factory/evidence/polish-5-clean-clone.json`.

## Deployment and durability evidence

Deployment used the work-order wrapper:

```bash
scripts/deploy-durable-container.sh \
  accessible-explanation-checkin /work/repo Dockerfile 8080
```

The final Azure control plane returned:

- latest and ready revision: `sf-accessible-explanation-9c1a54--0000060`;
- one active revision and one running replica;
- minimum and maximum replicas: 1;
- Azure File storage: `aec-accessible-explanati-9c1a54`;
- share: `sf-accessible-explanation-checkin-data`;
- mount: `/app/data`;
- image: `sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:5aa0519153e7`.

The deployment gate created a real private check-in on revision `0000059`.
It submitted an explanation and saved a teacher review. Student, review, and
receipt links each returned 24/24 successful independent reads. The gate then
forced revision `0000060` and confirmed a different running replica. All three
resources returned another 24/24 successful reads, and the review remained.

Evidence:

- `.factory/evidence/polish-5-live-durability.json`
- `.factory/evidence/polish-5-live-topology.json`

Always use `scripts/deploy-durable-container.sh` for this SQLite service. The
generic factory helper creates an intermediate stateless scaling template;
the product wrapper applies and verifies the required final topology.

## Cold live verification

The final cold audit opened the public site in fresh browser contexts after
deployment. It verified:

- `/`, `/demo`, `/create`, `/pricing`, `/privacy`, and `/terms` return 200;
- `/no-such-page` returns a designed HTTP 404;
- every route has one h1, one main landmark, correct title and canonical URL;
- Privacy and Terms links are visible, and all 14 crawled links are valid;
- link and history navigation focus the destination h1 and announce it;
- all measured touch targets are at least 44 pixels;
- 200% text has no horizontal overflow at 390 pixels;
- light and dark routes have zero serious or critical axe findings;
- `/?demo=1` loads three responses, uses only `demo:` storage, resets, and reloads offline;
- the real create, submit, review, save, and reload workflow succeeds;
- classroom workflow requests remain on the product origin;
- the $39 checkout is listed and returns a 303 to `checkout.dodopayments.com`;
- required security headers are present and browser console errors are zero.

The factory `verify-url.sh` also passed the cold home page. Its measured load
was 552 ms with title, `lang`, one h1, main, alt text, and button labels present.

A 150-request live burst returned 120 normal responses and 30 HTTP 429
responses. Every 429 included `Retry-After`.

Mobile Lighthouse 12.8.2 scores were 100 performance, 100 accessibility,
100 best practices, and 100 SEO. LCP was 1.052 seconds, CLS was 0, and total
blocking time was 0 ms.

Evidence:

- `.factory/evidence/polish-5-live-check.json`
- `.factory/evidence/polish-5-live-demo-mobile.png`
- `.factory/evidence/polish-5-live-404-mobile.png`
- `.factory/evidence/polish-5-verify-home/screenshot-desktop.png`
- `.factory/evidence/polish-5-verify-home/screenshot-mobile.png`
- `.factory/evidence/polish-5-verify-home/verify.json`
- `.factory/evidence/polish-5-rate-limit.json`
- `.factory/evidence/polish-5-lighthouse-mobile.json`

## Run locally

```bash
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
```

Use `npm run dev` for frontend and backend development. The production server
uses `PORT`, defaults to 8080, and creates its local data directory on first
boot.

## Known gaps and next steps

None for the reviewed scope. No finding or deferred minor item remains.
