# Independent verification 15 — FAIL

- Work order: `accessible-explanation-checkin-verify-15`
- Candidate commit: `a3e323a97cbbe7e1012b63db21037603fddaf777`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-30 UTC

## Verdict

**FAIL — release blocked by a critical live persistence failure.** The live
deployment is the requested candidate, and its local code, build, accessibility
and demo checks are strong. It is nevertheless not safe to release: the
production SQLite service is allowed to run three replicas, and a freshly
created real check-in disappeared during the ordinary student-to-receipt flow.

## Required first checks

### Claims gate

`.factory/claims.json` exists and declares 25 claims. After `npm ci`
(86 packages installed; npm reported 0 vulnerabilities), I invoked every
declared command individually from the clean checkout through its configured
demo entry point. The browser, Rust, fixture, runtime, voice, privacy, billing
fixture and local workflow claims completed without a retained failure. The
final `durable-deployment-policy` claim is release-blocking because its exact
live component fails:

```text
$ npm run verify:live-topology
ERROR: live topology check failed: expected minReplicas=maxReplicas=1;
observed minReplicas=1 maxReplicas=3
```

The same error was reproduced independently after the claim run. The local
parts of that compound claim pass: `npm test` reports the durable-deploy,
durable-workflow and topology fixtures as PASS. They are not evidence of the
real deployment state.

### Cold first read and demo

**PASS.** A new desktop browser visit returned 200 and plainly answered all
three required questions:

- What it does: **“Collect student reasoning.”**
- Who it is for: teachers who need a low-stakes check-in.
- What to do first: **“Try it with sample data”**, followed by “Open a
  populated teacher review; nothing is saved.”

One click opened `/demo`, a realistic watershed review containing three
responses, and showed the persistent **Demo — sample data, nothing is saved**
banner with **Reset demo** and **Start for real**.

## Critical finding

### Critical — private check-in state is not reliable in production

Fresh production browser/API evidence against this candidate:

1. A teacher POSTed a valid check-in and received **201** plus separate private
   student and review links.
2. The student link initially returned **200** and displayed the form.
3. A valid text explanation and confidence submission returned **201**.
4. The app immediately requested the returned private receipt token and got
   **404**, displaying **“We could not open this receipt.”**
5. An immediate private review request and a repeat student-link request also
   returned **404**.

This breaks the brief's essential reasoning-check-in record and the declared
`student-review-workflow` experience. It is consistent with requests landing
on independent SQLite replicas. The live deployment gate confirms the
underlying unsupported topology: `minReplicas=1`, `maxReplicas=3`, where
this product's own durable SQLite policy requires exactly one replica and the
Azure File mount.

**Required remediation:** deploy through the durable deployment wrapper, prove
one active healthy running replica with `minReplicas=maxReplicas=1` and the
read-write `/app/data` share mount, then demonstrate create → student submit
→ receipt → teacher review persistence across a real revision transition.

## Identity and local quality gates

- **Live identity: PASS.** `/health`, the root ETag, and hashed JS/CSS ETags
  all identify `a3e323a97cbbe7e1012b63db21037603fddaf777`. Fresh local and
  live SHA-256 values matched for `index-DSulbgta.js` and
  `index-ElpK5dHQ.css`.
- **`npm test`: PASS.** 5 Vitest tests, 13 Rust tests, and all three durable
  deployment fixtures passed.
- **Production build: PASS.** `npm run build` created `dist/`; JS is
  38.93 kB raw / 12.43 kB gzip and CSS is 19.42 kB raw / 5.19 kB gzip, inside
  the stated budgets.
- **Static/Rust checks: PASS.** TypeScript check, `cargo fmt --check`,
  strict `cargo clippy -- -D warnings`, and locked release build passed.
- **Runtime/container contracts: PASS.** Build-identity test passed; the
  non-root runtime claim passed while writing its durable snapshot.
- **Local browser suite: PASS.** `npm run test:e2e` completed its desktop and
  390 px app and claim shards with no retained failed-result artifacts. The
  desktop app shard explicitly reported 9 passed and 2 intentional
  mobile-only skips.

## Browser, accessibility, privacy and operations

- **Accessibility/mobile: PASS.** Direct axe scans at 390 px on `/`, demo,
  create, pricing, privacy, terms and the 404 page found no serious or critical
  violations. Each had one `h1`, one `main`, and no horizontal overflow.
  The first keyboard stop is the skip link; reduced motion produces
  `scroll-behavior: auto`. The factory `verify-url.sh` also passed for
  title, `lang=en`, main, image alt text, named buttons and zero landing-page
  console/page errors.
- **Privacy: PASS.** Fresh demo and attempted real-workflow Playwright request
  logs contained only `https://accessible-explanation-checkin.sociobot.in`.
  No analytics, advertising, model, font-CDN or other third-party request was
  observed. The product has no sign-in, so Entra tenant validation is not
  applicable.
- **PWA/demo: PASS.** After service-worker `registration.update()`, the
  controlled `/demo` page reloaded offline and retained the seeded
  “Watershed reasoning” review.
- **Headers/caching: PASS.** HTML revalidates; hashed assets use
  `public, max-age=31536000, immutable`; private API responses use
  `private, no-store`. Live responses include HSTS, `nosniff`,
  `Referrer-Policy: no-referrer`, Permissions Policy, and an HTTP CSP with
  `frame-ancestors 'none'`.
- **Rate limit: PASS.** A same-client concurrent burst of 180 harmless
  unknown-token API reads produced 82 normal 404 responses and 98 responses
  with HTTP 429. Every 429 included `Retry-After: 0`. Thus the observed
  allowance in this burst was 82 requests before throttling; the source policy
  declares a 120-request burst with one request/second refill.

## Defects by severity

1. **Critical / release-blocking:** Production permits three SQLite replicas
   and loses private student, receipt and review state between ordinary
   requests. The mandatory `durable-deployment-policy` claim fails.

No additional product defect was found in the completed local, demo,
accessibility, privacy, header, bundle or rate-limit checks.
