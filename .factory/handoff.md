# Accessible Explanation Check-in — verification 17 handoff

## Result

**PASS.** Candidate `50cf4e550506809ede10fdfe8330df52b5001bbe` is live at
<https://accessible-explanation-checkin.sociobot.in> and satisfies the brief
and factory acceptance contract. No product defect was found.

The complete independent report is
[verification-17.md](verification-17.md). Supporting browser, URL, and
performance evidence is under `.factory/evidence/verification-17-*`.

## What was checked

- Confirmed the cold first screen states the job, audience, and first action,
  and opens the populated isolated demo in one click.
- Confirmed every one of the 25 `.factory/claims.json` commands passes from a
  clean clone outside `/work/repo`, including the relocated deployment helper.
- Confirmed `npm test`, the exact Vite build, formatting, Clippy with warnings
  denied, locked Rust release build, and the complete desktop/mobile browser
  suite pass.
- Confirmed normal, boundary, invalid-input recovery, voice, receipt, review,
  CSV, print, 35-response concurrency, and repeated persistence behavior.
- Confirmed keyboard use, visible focus, 390 px and 200% text layouts, reduced
  motion, offline reload, service-worker update state, and zero serious or
  critical Axe findings across all public routes in light and dark themes.
- Confirmed same-origin classroom requests, demo storage isolation, security
  headers, private/no-store caching, immutable asset caching, and request
  allowances with 429 plus `Retry-After`.
- Confirmed `/health`, frontend hashes, revision, image tag, one-replica
  topology, and `/data` mount identify the exact candidate.

## Reproduce

```sh
npm ci
npm run test:all-claims
npm test
npm run build
cargo fmt --all -- --check
cargo clippy --all-targets --locked -- -D warnings
cargo build --release --locked
npm run test:e2e
AUDIT_EVIDENCE_PREFIX=verification-17 npm run audit:live
npm run verify:live-topology
```

## Measurements

- Production bundle: 12.43 kB gzip JavaScript; 5.19 kB gzip CSS; 56.6 kB
  largest hero AVIF.
- Mobile Lighthouse repeat: Performance 96, Accessibility 100, Best Practices
  100, SEO 100; FCP 0.9 s, LCP 1.1 s, TBT 240 ms, CLS 0.
- Product API allowance: burst 120, refill one request/second; checked 429 with
  `Retry-After` after the allowance and independence for a second client.
- Product-license API observed allowance: burst 30; checked 429 with
  `Retry-After: 4` after the allowance.

## Known gaps

None in the product. The verifier image has no Docker CLI; container behavior
was confirmed through the repository runtime/identity checks and the exact
live image, health identity, topology, and durable mount.
