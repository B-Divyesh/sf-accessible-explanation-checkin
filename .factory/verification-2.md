# Independent verification 2 — FAIL

- Work order: `accessible-explanation-checkin-verify-2`
- Verified: 2026-08-28 UTC
- Candidate: `de2386a7a15f0b34fb67c58d751d17be87f1a821`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>

## Verdict

**FAIL.** The deployed application is the requested candidate and the core
teacher → student → receipt → teacher-review workflow now works reliably. The
previous persistence, free-tier quota, billing-origin, caching, target-size,
and response-policy findings all pass fresh checks. This release is still not
acceptable under the supplied backend-service contract because its production
Docker runtime explicitly runs as `root`, despite the contract requiring a
non-root runtime user.

## Defects

### High — production container runs as root

`Dockerfile` creates a `checkin` user, then selects `USER root` immediately
before the runtime `ENV` and `CMD`. The accompanying comment confirms this is
intentional. The mandatory backend Docker contract requires a multi-stage,
**non-root** runtime user. A network-facing service that stores student text
and optional voice should not run as root merely to accommodate the current
Azure Files mount arrangement.

Use a mounted-path ownership/permissions strategy, a writeable non-root
runtime directory, or an init/sidecar arrangement, then restore `USER checkin`
and rebuild/retest the image. Docker and Podman were unavailable in this
verifier environment, so image execution/UID inspection could not be repeated;
the violation is directly evident in the candidate Dockerfile. The repository's
identity and deployment-policy scripts pass, but neither checks effective UID.

No other release-blocking defects were found in this retest.

## Clean-checkout gates

A detached worktree at the candidate SHA was clean before installation.

| Check | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages installed; 0 vulnerabilities reported |
| `npm test` | PASS — strict TypeScript, 4 Vitest assertions, Rust unit/integration tests, durable-deploy policy |
| `npm run build` | PASS — `dist/` produced |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |
| `cargo build --release --locked` | PASS |
| `npm run test:e2e` | PASS — 8/8 Chromium desktop + 390 px mobile tests |
| `npm run test:deploy-helper` | PASS — deterministic 32-character deployment name |
| `npm run test:container-identity` | PASS — build SHA wiring |
| `npm run test:deployment-policy` | PASS — one Azure File-backed durable replica policy |

The exact production frontend build is 32.28 KB JavaScript (10.91 KB gzip),
17.82 KB CSS (4.87 KB gzip), and an 18.66 KB 768 px AVIF hero; all applicable
bundle budgets pass. No downloaded webfonts are used.

## Fresh functional and backend evidence

- The release binary started with only `PORT=18081` supplied. Its structured
  startup line identified generated defaults without leaking secrets; `/health`
  returned `200` with `build_sha: "development"` locally.
- Local API boundary checks accepted exact free limits (120-character title,
  1,200-character prompt, 4,000-character explanation, 1/5 and 5/5
  confidence, 7-day retention), rejected an empty/short invalid create payload
  with `400`, and rejected malformed Base64 voice with `400` and an actionable
  message.
- A local 40-way simultaneous submission test returned exactly **35 × 201** and
  **5 × 409**; the follow-up read reported `submissions: 35`,
  `max_submissions: 35`, and `open: false`.
- A locally created check-in remained readable after graceful stop/restart.
- At the live URL, a fresh teacher check-in returned `201`; **25/25** immediate
  student-link reads and **25/25** matching review-link reads returned `200`.
  Invalid submission recovered with `400`, then a valid response returned `201`;
  review update, private receipt, and CSV export each returned `200`.
- A live 100-request concurrent `/health` smoke returned **100/100 200**.

## Deployment identity, privacy, and response policy

`GET /health` at the live URL returned:

```json
{"build_sha":"de2386a7a15f0b34fb67c58d751d17be87f1a821","status":"ok"}
```

The served `index.html` matches the clean `dist/index.html` byte-for-byte. The
production JS hash matched `ac926dc02fa552e033e1b2e646d5a0d185a0e06c5a50bd7c66dfa3763a4ec0cc`;
the service worker hash matched
`c3ecd512f954ab78c994d9ea351d8a23d3084dcc63dfa7ef3f9ae45129a652cb`.

- HTTP redirects to HTTPS. Live responses include CSP, `nosniff`,
  `Referrer-Policy: no-referrer`, HSTS, and Permissions Policy.
- Private student/review/receipt/CSV responses returned `Cache-Control:
  private, no-store`; hashed assets returned `public, max-age=31536000,
  immutable`; shell returned revalidation caching plus an ETag.
- Normal Chromium loads of `/privacy` made requests only to the product origin
  and left no cookies. No third-party scripts, styles, analytics, or CDN fonts
  were observed. The Plans route uses `https://api.sociobot.in`, not the pilot
  endpoint.

## Browser, accessibility, PWA, and performance evidence

- Chromium audited `/`, `/create`, `/pricing`, `/privacy`, and `/terms` at
  desktop and 390 × 844 mobile: one `<h1>`, one `<main>`, and **zero axe
  serious/critical findings** on every audited page; no console/page errors.
- At 390 px there was no horizontal overflow. Measured targets: theme toggle
  44 × 44.8 px, Privacy 63.2 × 44 px, Terms 55.2 × 44 px.
- Keyboard-only smoke: the first Tab stop is “Skip to main content”, with a
  visible `rgb(157, 66, 28) solid 3px` outline; Enter moves focus to `#main`.
  With reduced motion, transition and animation durations computed as
  `0.00001s`.
- The service worker controlled the page, one registration completed an update,
  and a 390 px offline reload rendered both the cached home content and visible
  Offline status without console errors.
- Fresh live Lighthouse mobile: **98 Performance, 100 Accessibility, 100 Best
  Practices, 100 SEO**; FCP 1.6 s, LCP 2.1 s, TBT 0 ms, CLS 0.

## Required retest

Change the image to run non-root, build and run that image with only `PORT`
supplied, verify writable durable snapshots/uploads as the runtime UID, then
rerun the container identity, live health/build-identity, persistence, and
full QA suite. Do not change this verdict until that succeeds.
