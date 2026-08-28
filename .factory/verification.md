# Independent verification — FAIL

- Work order: `accessible-explanation-checkin-verify-1`
- Verified: 2026-08-28 UTC
- Candidate: `aad48951be0ac176a263a9d1c0cd5b00a9de01c3`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>

## Verdict

**FAIL.** The candidate builds cleanly, passes its automated suites, has strong
baseline accessibility and performance, and is the exact version currently
served. It is not releasable because the live backend does not provide a
consistent persistence boundary: a check-in created successfully is absent on
most immediately following reads. The local backend also allows concurrent
submissions to exceed the promised free-tier limit, and the production paid
flow points to the pilot billing API.

## Defects

### Critical — live records are split across serving instances

Fresh live evidence disproves the earlier deployment-success conclusion:

- `POST /api/checkins` returned `201` and issued a student token and a review
  token.
- Twenty immediate reads of that student token returned **7 × 200 and 13 ×
  404**.
- Twenty immediate reads of the matching review token returned **6 × 200 and
  14 × 404**.
- All requests used the same public address, `20.96.41.97`; the alternating
  bodies were either the correct record or
  `{"error":"That private link is not valid..."}`.
- An independent live Chromium journey failed at the same boundary: after the
  teacher received links, the new student link rendered the invalid-link state
  instead of the form.

The observed behavior is consistent with requests being balanced across
instances that use separate local SQLite files. It makes the primary
teacher-to-student-to-review workflow unreliable and risks records disappearing
as instances or revisions change. Use one durable shared persistence boundary
or force a single durable instance, then verify cross-request and restart
behavior at the deployed URL.

### High — concurrent submissions overrun the declared quota

Against a fresh release binary and SQLite database, 40 simultaneous valid
submissions to a free check-in produced **39 × 201 and 1 × 409**. A subsequent
read returned:

```json
{"open":false,"submissions":39,"max_submissions":35}
```

The count check and insert are not atomic. Enforce the quota in one transaction
or with a database constraint/atomic statement, and add a concurrent regression
test.

### High — the production paid flow uses the pilot billing service

On the live Plans page:

- “Buy Classroom Plus” resolves to
  `https://pilot-api.sociobot.in/api/v1/products/accessible-explanation-checkin/checkout`.
- Restoring a deliberately invalid token sent its verification request to the
  corresponding `pilot-api.sociobot.in` endpoint.
- The deployed JS bundle contains only `https://pilot-api.sociobot.in` as its
  billing origin.

The production work order requires `https://api.sociobot.in`. Rebuild with the
production billing base for both browser and server, then exercise checkout
return, storage, verification, daily cache, revocation, and restore.

### Medium — private API responses do not prohibit caching

A successful live bearer-token request to `/api/checkins/<token>` returned no
`Cache-Control` header. Review and receipt JSON use the same response path.
Voice and CSV responses correctly send `private, no-store`. Apply equivalent
private/no-store policy to all bearer-token JSON and HTML navigation responses.

### Medium — several mobile targets are smaller than the 44 × 44 contract

At 390 px, computed hit boxes were 30 × 45 px for “Change color theme”, 47 × 22
px for “Privacy”, and 39 × 22 px for “Terms”. There was no horizontal overflow,
but these controls do not meet the supplied touch-target requirement.

### Low — static assets have no explicit caching policy

The hashed JS/CSS, images, shell HTML, service worker, and manifest all omitted
`Cache-Control` and `ETag`. Lighthouse reported the cache-lifetime audit as
failing with an estimated 34 KiB saving. Serve hashed assets as long-lived and
immutable; keep HTML and `sw.js` short-lived/revalidated.

### Low — response/startup hardening is incomplete

HTTPS and HTTP-to-HTTPS redirect work, and responses include CSP,
`frame-ancestors 'none'`, `nosniff`, and `Referrer-Policy: no-referrer`.
However, the live response does not include HSTS or Permissions Policy. Also,
the required startup line identifying generated versus supplied configuration
is absent; startup emitted only cleanup and listen messages.

## Clean-checkout build and automated checks

A detached worktree at the candidate SHA was clean before installation.

| Command | Result |
| --- | --- |
| `npm ci` | PASS; 86 packages installed, 0 vulnerabilities |
| `npm test` | PASS; strict TypeScript check, 3/3 Vitest, 3/3 Rust tests |
| `npm run build` | PASS; `dist/` produced |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm run test:deploy-helper` | PASS; deterministic 32-character app name |
| `npm run test:container-identity` | PASS; Dockerfile build-identity contract |
| `npm run test:e2e` | PASS; 4/4 desktop/mobile Chromium tests |

Docker/Podman was not installed in the verifier environment, so the Dockerfile
could not be rebuilt locally. Both constituent production builds passed, the
candidate's Docker contract test passed, and the live build identity plus
byte-for-byte asset comparison independently verified the deployed artifact.

## Independent functional evidence

The release binary started in a fresh directory with only `PORT=18080` in its
environment. Local persistence survived a graceful stop/restart. One hundred
health requests at concurrency 10 all returned 200.

The independent local browser journey passed: teacher creation, empty review,
student form error and recovery, automatic local draft save/reload, confidence,
submission, private receipt, teacher tags/note/follow-up, save confirmation,
and CSV download. The download name was `explanation-checkin.csv`; no console or
page errors occurred. Keyboard checks confirmed the skip link is the first Tab
stop, has a visible 3 px focus ring, and moves focus to `<main>`.

API boundary and recovery checks passed for:

- exact maxima: 120-character title, 1,200-character prompt, 80-character name,
  4,000-character explanation, confidence 1/5 and 5/5, retention 1/7 days;
- empty title/name, three-character prompt, 81-character name, 4,001-character
  explanation, confidence outside 1–5, retention outside 1–7;
- missing text and voice, invalid Base64, unsupported voice MIME, invalid bearer
  link, cross-link voice access, invalid review tags, and a 1,001-character note;
- 6 MiB-plus request rejection (`413`), voice retrieval with `private,
  no-store`, teacher deletion, and post-deletion `410`;
- spreadsheet-formula neutralization in CSV (`=SUM(...)` exported with a
  leading apostrophe).

## Live browser, accessibility, privacy, and PWA evidence

- Audited home, create, plans, and privacy in Chromium at 1440 × 900 and 390 ×
  844, plus dark and reduced-motion variants: **0 serious/critical axe findings**,
  one `<h1>`, one `<main>`, `lang="en"`, descriptive titles, no horizontal
  overflow, and no console/page/request errors.
- Reduced-motion styles reduced transitions/animations to 0.00001 s and no
  looping motion was observed.
- Normal audited page loads contacted only the product origin. No cookies,
  analytics, CDN font, or third-party script/style requests were observed.
- The service worker activated and controlled the page; `registration.update()`
  completed, and a 390 px offline reload rendered the cached home screen and
  visible “Offline” status without errors.
- Live Lighthouse 12.8.2 mobile: **Performance 99, Accessibility 100, Best
  Practices 100, SEO 100**; FCP 1.0 s, LCP 1.1 s, TBT 120 ms, CLS 0, 35 KiB
  transferred over 7 requests. Lab INP is not emitted without interaction.
- Production build sizes: JS 32.28 KB (10.91 KB gzip), CSS 17.68 KB (4.85 KB
  gzip), mobile AVIF hero 18.66 KB, no downloaded fonts. All size budgets pass.

## Deployment identity

`GET /health` returned:

```json
{"build_sha":"aad48951be0ac176a263a9d1c0cd5b00a9de01c3","status":"ok"}
```

Live and clean-build SHA-256 hashes matched for `index.html`, JS, CSS, `sw.js`,
`manifest.webmanifest`, and the 768 px AVIF hero. Examples:

- `index.html`: `04df0dfe61af956706670deaa24583e9d181e00fd03f1e72883791c352144625`
- JS: `52d8ec4a6a2c35281801dd2df30892705d333259d0a8daec5745158063626c1d`
- CSS: `504e8f5bcba84d591aed03bd17f166d25b53585638e07e701ca4145db3e9475c`
- service worker: `c3ecd512f954ab78c994d9ea351d8a23d3084dcc63dfa7ef3f9ae45129a652cb`

The certificate validated, HTTP/2 was served, and HTTP redirected to HTTPS.

## Required retest

After repair, repeat the live create/read/submit/review sequence across many
requests and after an instance restart; rerun the 40-way quota test; confirm
the live buy/verify origins are `api.sociobot.in`; verify no-store headers and
44 px targets; then rerun all gates and Lighthouse.
