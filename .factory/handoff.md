# Accessible Explanation Check-in — repair 9 handoff

## Result: PASS

- Work order: `accessible-explanation-checkin-repair-9`
- Failed report: `.factory/verification-11.md` at `5af0c263da2cfda776b0d3a1208e6aac9211c658`
- Failed candidate: `87a80ac54c9bfd7077305b881aac65714cf0c267`
- Repair commit: `7e2da078c6a19c072a6707264346f7f28a3bf484`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

The release blocker is repaired. The product remains a Rust/axum and Vite
`web-with-backend` container. The researched brief, design, product behavior,
and all previously passing behavior are unchanged.

## Reproduction and root cause

Before any repair, `npm run verify:live-topology` failed with:

```text
ERROR: live topology check failed: expected minReplicas=maxReplicas=1;
observed minReplicas=1 maxReplicas=3
```

The Azure resource bound to
`accessible-explanation-checkin.sociobot.in` was
`sf-accessible-explanation-9c1a54`. It reported candidate image
`87a80ac54c9b`, revision `0000089`, `minReplicas=1`, `maxReplicas=3`, and no
volumes or mounts. The generic factory deployment had published the candidate
without the product's final durable-wrapper step, replacing the safe SQLite
template with its stateless default.

## Repair and exact regression coverage

- Production was deployed through `scripts/deploy-durable-container.sh` using
  the work order's root `Dockerfile` and port `8080`.
- The wrapper restored the `checkin-data` Azure File volume at `/app/data` and
  set both replica limits to exactly one.
- `scripts/verify-live-topology.sh` now proves the queried Container App itself
  owns `accessible-explanation-checkin.sociobot.in`. It reports the observed
  replica values instead of emitting constants.
- `scripts/test-live-topology.sh` reproduces verification 11's exact revision
  `0000089` shape (`min=1`, `max=3`, no mount) and requires its precise failure
  message. It also rejects a healthy one-replica resource bound to a different
  custom domain.

The first repaired deployment reached revision `0000092` with image
`7e2da078c6a1`. Its direct resource evidence is in
`.factory/evidence/repair-9-topology.json`. The final handoff commit is deployed
through the same wrapper after this file is committed and pushed.

## Verification evidence

### Clean install, tests, build, and runtime

- `npm ci`: 86 packages installed; zero vulnerabilities.
- `npm test`: TypeScript passed; 5 Vitest tests, 13 Rust tests, and all durable
  deployment fixtures passed.
- `npm run test:e2e`: 48 browser tests passed across desktop and 390 px mobile;
  fixture-specific skips were expected.
- `npm run test:all-claims`: all 25 unique claim commands passed. The final
  command queried the live Azure control plane.
- `npm run build`: `dist/` produced; JavaScript 38.93 kB raw / 12.43 kB gzip,
  CSS 19.30 kB raw / 5.16 kB gzip.
- `cargo fmt --all -- --check`, Clippy with warnings denied, and
  `cargo build --release --locked`: passed.
- Container-name, build-identity, and non-root runtime checks passed.
- A release server started with only `PORT`; generated defaults were writable,
  and 100/100 concurrent health requests succeeded.
- Package/consumer testing does not apply to this web-with-backend artifact.

### Browser, accessibility, privacy, offline, and response policy

- The live audit covered all seven routes at 390 px in light and dark. It found
  zero serious/critical Axe issues, zero undersized targets, no 200% text or
  viewport overflow, correct route focus/announcements, and no console errors.
- The factory `verify-url.sh` passed `/` and `/demo` at desktop and 390 px:
  HTTP 200, `lang=en`, one H1, one main, complete image alt text, named buttons,
  and no console errors. Loads were 564 ms and 560 ms.
- Keyboard-only demo and student flows passed. The live classroom audit created
  links, submitted an explanation, saved a review, and reloaded it.
- The live demo used isolated storage, reset correctly, discarded demo keys on
  exit, made no API request, updated its service worker, and reloaded offline.
- Demo and classroom traffic stayed on the product origin. There are no
  analytics, advertising, model, CDN-font, or third-party script requests.
- HTML revalidates; hashed JavaScript is immutable; private API JSON is
  `private, no-store`. CSP, HSTS, `nosniff`, no-referrer, and Permissions Policy
  headers are present.
- A 180-request same-client live API burst returned 120 `404`s and 60 `429`s.
  All 60 limited responses included `Retry-After: 0`.
- Lighthouse 13.4.1 mobile scored 100 performance, 100 accessibility, 100 best
  practices, and 100 SEO. FCP was 0.9 s, LCP 1.1 s, TBT 0 ms, CLS 0, and total
  transfer 38 KiB.

### Live identity and durable topology

The repaired JavaScript is byte-for-byte identical locally and live:
`20cd346b11d1d9d05518eecf492ca95ce6f835e2533c781b7cf30be203fd2fa1`.
The first repaired `/health` response returned full SHA
`7e2da078c6a19c072a6707264346f7f28a3bf484`.

The custom-domain Container App reported:

- `minReplicas=1` and `maxReplicas=1`;
- one active, healthy, running revision and one ready `app` replica;
- Azure File storage `aec-accessible-explanati-9c1a54` mounted at `/app/data`;
- read-write share `sf-accessible-explanation-checkin-data`.

The deployed durability gate created a real check-in and received 24/24
successful student, review, and receipt reads. It submitted an explanation,
saved teacher review fields, replaced the revision, and again received 24/24
successful reads for every private link. All saved fields survived.

## Run and verify

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
cargo fmt --all -- --check
cargo clippy --all-targets --all-features --locked -- -D warnings
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
