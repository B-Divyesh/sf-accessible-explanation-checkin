# Handoff — Accessible Explanation Check-in

Build work order: `accessible-explanation-checkin-build-1`
Completed: 2026-08-28

## What shipped

- A production-shaped teacher/student workflow served by one Axum container:
  teacher creates a prompt, receives distinct unguessable student/review links,
  student answers in text and/or optional voice with confidence, teacher tags
  and annotates responses, and the student receives a private receipt.
- Teacher CSV export and a print-optimized receipt (“Print or save PDF”). These
  core exports are available on the free tier.
- Voice capture, playback, 4 MB / 2-minute client cap, teacher deletion, stated
  expiry timestamps, and server cleanup at startup and hourly.
- SQLite persistence with parameterized SQL, input limits, 6 MB request cap,
  spreadsheet-formula-safe CSV, structured JSON logs, request IDs, security
  headers, a 120-request burst rate limit, and graceful shutdown.
- Honest empty, loading, invalid-link, quota, field-error and offline states.
  Student drafts are stored only on the current device until submission.
- Classroom Plus: $39 one-time hosted Sociobot checkout, query-token capture,
  local restore field, daily cached browser verification, background
  reconciliation, and server verification before allowing 500-response or
  1–365-day retention settings. Free limits are 35 responses and 1–7 days.
- `/privacy` and `/terms`, PWA manifest and versioned service-worker shell,
  light/dark themes, print styles, and responsive layouts down to 390 px.
- Original cinematic classroom art generated for this product, visually
  reviewed, and shipped as AVIF/WebP/JPEG responsive derivatives. The prompt,
  source PNG and provenance are under `assets/src/`; direction and tokens are
  in `.factory/design.md`.

## How to run and verify

```sh
npm ci
npm test
npm run build
npm run test:e2e
cargo build --release --locked
PORT=8080 cargo run
```

Container build command:

```sh
docker build -t accessible-explanation-checkin .
docker run --rm -p 8080:8080 -v checkin-data:/app/data accessible-explanation-checkin
```

The deploy artifact is a container. The exact frontend build command is
`npm run build`; it writes `dist/index.html`. The multi-stage Dockerfile builds
that directory, compiles the locked Rust release, runs as the non-root
`checkin` user, and exposes port 8080.

## Verification results

- `npm test`: pass — TypeScript typecheck, 3 Vitest tests, 3 Rust tests.
  The Rust integration test covers create/read/submit (including voice), review
  update, receipt, CSV export, voice retrieval/deletion, and health.
- `npm run test:e2e`: pass — 4 Playwright tests across desktop Chromium and a
  390×844 Chromium viewport. It covers the full user journey and scans landing,
  legal, student, teacher, light, dark, and reduced-motion views with axe.
- Axe: zero serious or critical issues in tested views.
- Factory `verify-url.sh`: pass — title, `lang=en`, one `h1`, main landmark,
  image alt, labelled buttons, and zero console errors; local load 633 ms.
- Lighthouse 12.8.2 mobile, local production build: **Performance 100,
  Accessibility 100, Best Practices 100, SEO 100**. LCP 1.4 s, CLS 0,
  total blocking time 10 ms, total transfer 38 KiB in the measured run.
- Bundles: 32.25 KB JS / 17.68 KB CSS uncompressed; mobile hero AVIF 19 KB,
  WebP 16 KB, JPEG fallback 32 KB; all are below the specified budgets.
- Load smoke: 100 requests at 10 concurrent clients to `/health`; 100/100
  completed, 1.76 ms mean and 13 ms max local latency.
- `git diff --check`: pass after formatting.

Evidence is saved in `.factory/evidence/` (verification JSON/screenshots and
Lighthouse JSON).

## Deployment notes and known gaps

- Set both `BILLING_BASE_URL` and build-time `VITE_BILLING_BASE_URL` to
  `https://api.sociobot.in` at release. Defaults intentionally use the pilot
  endpoint. The factory still needs to register the product/return URL; no
  product ID is hardcoded.
- Mount `/app/data` on durable storage. The SQLite database and voice directory
  must be backed up/restored together. The current v1 is a single-instance
  SQLite service, as scoped; multi-school SSO/admin policy is not included.
- The host did not provide Docker/Podman, so the Dockerfile could not be invoked
  locally. Both constituent locked builds were run successfully, and the image
  uses conventional Node/Rust builder stages plus a non-root Debian runtime.
- Browser voice support depends on `MediaRecorder`; unsupported/denied devices
  receive an explicit text alternative. The browser records format-valid audio;
  the backend validates declared MIME type and size but does not transcode it.
- Full-record erasure currently goes through the service contact/teacher, as
  stated in `/privacy`; a self-service bearer-link deletion flow would be the
  next privacy improvement.
