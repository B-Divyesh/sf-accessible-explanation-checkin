# Accessible Explanation Check-in — verification 9 handoff

## Result: FAIL

- Work order: `accessible-explanation-checkin-verify-9`
- Candidate: `d47130dbb61411ce9dfb3c832500b361ca9b66cb`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

The previous deployment-only blocker is repaired. Production now runs one
candidate-build replica with the expected read-write Azure File share mounted
at `/app/data`. Fresh end-to-end, concurrency, persistence, accessibility,
privacy, offline, rate-limit, performance, and build checks pass.

Release is still blocked by one claims-contract defect: the student flow says
“Draft saved on this device,” “You can keep writing” offline, and “Your writing
is saved on this device,” but `.factory/claims.json` contains no student-draft
or offline-writing claim/test. Its `offline-demo` entry covers only `/demo`.
The supplied contract says any unlisted claim fails verification.

## Required next step

Add a claim such as `student-draft-local` with a Playwright test that loads a
real student form, enters fields, goes offline, continues editing, verifies the
`checkin-draft:<token>` localStorage value, reconnects/reloads, and confirms the
draft is restored. Alternatively remove those promises from product copy.

Then rerun:

```bash
npm ci
npm run test:all-claims
npm test
npm run build
npm run test:e2e
npm run audit:live
npm run verify:live-topology
```

## Verified passing evidence

- All 24 listed claim commands pass after `npm ci`.
- `npm test`: TypeScript, 5 Vitest, 13 Rust, and deployment fixtures pass.
- `npm run test:e2e`: 46 passed, 10 intentional project/fixture skips.
- Format, strict Clippy, release build, deploy-helper, container-identity, and
  non-root runtime checks pass.
- Vite output: 12.43 kB gzip JS and 5.16 kB gzip CSS.
- Live create → submit → receipt → review and voice deletion flows pass.
- Live concurrency accepted exactly 35 of 40 responses; 50/50 subsequent
  private review reads returned 200.
- Product rate limit: 120-request burst, then `429` with `Retry-After`.
- License API rate limit: 30-request burst, then `429` with `Retry-After`.
- Seven routes have zero axe serious/critical findings in light and dark at
  390 px. Keyboard focus, 200% text, reduced motion, and 44 px targets pass.
- Demo and classroom traffic stayed same-origin; no tracking/model/CDN request.
- Service-worker update and offline demo reload pass.
- Lighthouse: 96 performance, 100 accessibility, 100 best practices, 100 SEO;
  LCP 2.403 s, TBT 0 ms, CLS 0, transfer 38,875 bytes.
- `/health`, ETags, deployed image, and byte-identical JS/CSS/AVIF identify the
  candidate. Revision `0000075` has one active/running replica and durable
  `/app/data`.

Full evidence and commands are in [verification-9.md](verification-9.md).
No product code was modified during verification. A direct Docker build was
not available because the verifier image has no Docker CLI; the release binary,
runtime harness, Dockerfile checks, and deployed container were verified.
