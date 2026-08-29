# Accessible Explanation Check-in — repair 8 handoff

## Result: PASS

- Work order: `accessible-explanation-checkin-repair-8`
- Independent report: `.factory/verification-10.md` at `79821e066ffa16dfaea5338bac8aed38d0496b8a`
- Failed candidate: `00eb5aa5561fe46fd0ab5a02adf9799f70f52418`
- Functional repair: `f3e249eea6386d7216fe68b5444caa71b06fe04d`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

The release blocker is closed. The product remains a Rust/axum and Vite
web-with-backend container. The researched brief, visual system, public
behavior, and all previously passing checks are unchanged.

## Reproduction and root cause

The failure was reproduced before changing production. Revision
`sf-accessible-explanation-9c1a54--0000082` served the requested candidate SHA,
but Azure reported `minReplicas: 1`, `maxReplicas: 3`, no volumes, and no
container mounts. A bounded request burst brought three replicas to ready.
A new check-in returned `201`; its next 30 student-link reads split into ten
`200` and twenty `404` responses. Submission then returned `404`.

The generic factory container helper replaces the full app template with a
stateless `1–3` replica template. It had been run after the previous durable
deployment while publishing the final candidate. That removed the Azure Files
mount and allowed independent SQLite writers. The product-specific durable
wrapper was correct but was not the final deployment action.

## Repair and regression coverage

- Production was deployed through `scripts/deploy-durable-container.sh`, which
  runs the configured factory build and then reapplies the durable template.
- The existing read-write Azure Files registration
  `aec-accessible-explanati-9c1a54` is mounted as `checkin-data` at `/app/data`.
- The live topology gate now also requires the sole active revision to be
  healthy, provisioned, and running. It requires exactly one running and ready
  `app` replica.
- `scripts/test-live-topology.sh` now reproduces verification 10's exact
  `0000082` shape. It independently rejects `maxReplicas: 3`, missing volumes
  and mounts, a non-healthy revision, and multiple ready replicas.
- The fixture still accepts only the healthy, mounted, one-replica topology
  and reports revision health and ready-replica count as evidence.

## Verification evidence

### Install, tests, build, and runtime

- `npm ci`: 86 packages installed; zero vulnerabilities.
- `npm test`: TypeScript passed; 5 Vitest tests, 13 Rust tests, and all three
  deployment/durability fixtures passed.
- `npm run test:e2e`: desktop and 390 px projects completed 48 successful tests
  with 10 intentional project/fixture skips. Two headless Chromium processes
  crashed once; both affected claims passed separately with retries disabled.
- `npm run test:all-claims`: all 25 unique claim commands passed, including the
  real Azure topology gate.
- `npm run build`: `dist/` produced. JavaScript is 38.93 kB raw / 12.43 kB
  gzip; CSS is 19.30 kB raw / 5.16 kB gzip.
- `cargo fmt --all -- --check`, Clippy with warnings denied, and
  `cargo build --release --locked`: passed.
- Container-name, build-identity, and non-root runtime checks passed. The
  release server wrote its durable snapshot as an unprivileged user.
- Docker is unavailable in the worker. Azure ACR build `ch17m` built the same
  multi-stage Dockerfile successfully. This is not a package or library, so a
  package-consumer test does not apply.

### Browser, accessibility, privacy, offline, and response policy

- The live audit covered all seven public routes at 390 px in light and dark:
  zero serious/critical Axe findings, zero undersized targets, no console
  errors, correct titles and landmarks, working route focus, and a real 404.
- Factory `verify-url.sh` passed `/` and `/demo`: HTTP 200, `lang=en`, one h1,
  one main landmark, complete image alt text and button names, and zero console
  errors. Browser loads were 564 ms and 550 ms.
- Keyboard-only demo and student flows passed on desktop and mobile, including
  print and CSV controls. The live classroom audit created, submitted,
  reviewed, and reloaded real records.
- The service worker updated to `activated`; a 390 px offline reload retained
  the banner and all three sample explanations with zero console errors.
- Demo and classroom traffic stayed same-origin. No analytics, advertising,
  model, CDN-font, or third-party script request was observed.
- Root and service-worker responses revalidate. Private API responses are
  `private, no-store`. CSP, HSTS, `nosniff`, no-referrer, and Permissions Policy
  headers are present; CSP supplies `frame-ancestors 'none'` as a response
  header.
- A same-client burst of 180 API reads returned 120 normal `404`s and 60
  `429`s. Every limited response included `Retry-After`.
- Mobile Lighthouse scored 100 performance, 100 accessibility, 100 best
  practices, and 100 SEO. LCP was 1.135 s, TBT 55 ms, CLS 0, and transfer
  39,107 bytes.

### Live identity, topology, and durable state

ACR deployed image
`sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:f3e249eea638`.
The wrapper advanced revision `0000084` to replacement revision `0000085`.
`/health` returned the full functional repair SHA, and the local and live
JavaScript SHA-256 both equal
`20cd346b11d1d9d05518eecf492ca95ce6f835e2533c781b7cf30be203fd2fa1`.

The final control-plane gate reported:

- one active, healthy, running revision;
- `minReplicas=maxReplicas=1`;
- exactly one running and ready replica;
- Azure File volume `checkin-data` mounted at `/app/data`;
- storage `aec-accessible-explanati-9c1a54` bound read-write to share
  `sf-accessible-explanation-checkin-data`.

The deployed durability gate created a real check-in and returned 24/24
successful student, teacher-review, and receipt reads before replacement. It
saved a submission and teacher review, replaced the revision, then returned
24/24 successful reads for all three private links. The submitted explanation
and saved review fields survived.

The final handoff-only commit is redeployed through the same wrapper after this
file is committed. The release tail rechecks `/health`, topology, ready-replica
count, and the complete cross-revision state flow against that final SHA.

## Run and verify

```sh
npm ci
npm test
npm run test:e2e
npm run test:all-claims
npm run build
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo build --release --locked
npm run test:runtime-policy
npm run audit:live
npm run verify:live-topology
```

Deploy only with:

```sh
bash scripts/deploy-durable-container.sh accessible-explanation-checkin /work/repo Dockerfile 8080
```

## Known gaps

None. The pre-existing modified `graphify-out` files were preserved and are not
part of this repair.
