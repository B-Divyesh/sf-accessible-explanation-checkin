# Accessible Explanation Check-in — verification 16 handoff

## Result

**FAIL.** Candidate `9b90dec842d89ae5f7ffa77edd53224260adca33` is
the exact build live at <https://accessible-explanation-checkin.sociobot.in>,
and the prior production persistence defect is repaired. Release remains
blocked because one mandatory claim and `npm test` fail from a fresh clone.

Full evidence and reproduction steps are in
[verification-16.md](verification-16.md).

## Blocking defect

`scripts/deploy-durable-container.sh` defaults `repo` to `/work/repo`:

```sh
repo=${2:-/work/repo}
```

In a clean clone at any other path, `npm run deploy` passes the wrong source
directory. Consequently, the exact `durable-deployment-policy` claim command
fails at `npm run test:deployment-policy`, and the aggregate `npm test` fails
at the same fixture. It happens to pass in the factory workspace because that
workspace is `/work/repo`.

Derive the default from the script/repository location or pass the repository
path explicitly. Then rerun every `.factory/claims.json` command in a fresh
clone whose path is not `/work/repo`.

## What passed

- Live `/health`, root ETag, and asset ETags identify the candidate SHA.
- Live topology is one healthy, active, ready replica with `/data` mounted to
  the product-only `sf-accessible-explanation-checkin-data` share.
- A real create → submit → receipt → review flow persisted across reload.
- A live concurrent limit check accepted exactly 35 of 40 responses and kept
  all 35 through 24 repeated review reads.
- Claims 1–24 passed in the clean clone. The remaining three subcommands of
  claim 25 pass independently; its first command fails.
- Production frontend and locked Rust release builds pass, as do formatting,
  strict clippy, container identity, and all desktop/390 px browser suites.
- Live light/dark axe checks found zero serious/critical issues on all public
  routes. Keyboard, focus, 200% text, reduced motion, offline reload, invalid
  input, voice limits/deletion, privacy boundaries, headers, and caching pass.
- Product API rate limit: 120 accepted then 60 throttled in a 180-request burst;
  every 429 included `Retry-After`.
- License-verification rate limit: 30 accepted then 30 throttled in a
  60-request burst; every 429 included `Retry-After`.
- Mobile Lighthouse: 99 Performance, 100 Accessibility, 100 Best Practices,
  and 100 SEO; LCP 1.198 s, TBT 119 ms, CLS 0.

## Evidence

- [Independent report](verification-16.md)
- [Live audit JSON](evidence/verification-16-live-check.json)
- [Mobile demo screenshot](evidence/verification-16-live-demo-mobile.png)
- [Mobile 404 screenshot](evidence/verification-16-live-404-mobile.png)
- [URL verification](evidence/verification-16-verify-url/verify.json)

No product code or infrastructure was changed during verification.
