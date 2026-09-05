# Verify student explanation check-ins — verification 21 handoff

## Result

**FAIL — one critical deployment-identity finding; zero untested claims.**

- Implementation candidate: `8f2956bf5bafed7b9d0b27b53b92bf9cf3abd6bd`
- Repair documentation: `bd999e723236f2583b9a7e2fb239df3a798cc898`
- Current checkout head: `633f153e48e82764d412329b7089ae88ae062db6`
- Live revision checked: `sf-accessible-explanation-9c1a54--0000151`
- Full report: [verification-21.md](verification-21.md)

The live service now runs immutable digest `sha256:b96f54e3…` and `/health`
reports `633f153…`. Candidate `8f2956bf…` resolves to digest
`sha256:ee3d2502…`. Therefore `npm run verify:live-topology`, the final command
in the declared durable-deployment claim, fails. This reopens verification
20's blocker after repair 17's successful revision `0000150` deployment.

The live JS, CSS, and hero asset hashes match the clean candidate build. No
user-facing product-code regression was found. Product code was not changed.

## What was checked

- Fresh phone and desktop first screens state the job, teacher audience, first
  sample action, and result before scrolling.
- The one-click demo has three realistic explanations, a persistent sample
  label, reset, CSV, offline reload, and full disposal on exit. It makes no API
  request and does not touch real records.
- Real create, invalid input, 1,200/1,201 prompt boundary, student submission,
  receipt, teacher review, reload, voice boundary, voice deletion, and complete
  deletion paths passed. Every QA-created record was deleted.
- An actual replica restart preserved student, review, receipt, and saved
  teacher-review state. The service has one healthy ready replica and `/data`
  is mounted.
- All public routes, legal pages, links, route titles, focus restoration,
  keyboard paths, 200% text, reduced motion, both themes, the deliberate 404,
  privacy requests, service-worker state, and offline demo passed.
- Axe found no serious or critical issue. Factory URL checks passed without
  console errors.
- A 150-request burst returned 30 HTTP 429 responses, all with `Retry-After`.
- Lighthouse mobile: Performance 99, Accessibility 100, Best Practices 100,
  SEO 100; LCP 1.181 s, TBT 123 ms, CLS 0, transfer 39,445 bytes.
- All earlier verification, review, polish, and repair findings were inspected.
  Only deployment identity has recurred.

## Clean-checkout commands

From a detached checkout of `8f2956bf…`:

```sh
npm ci
npm run test:all-claims
npm test
npm run build
cargo fmt --all -- --check
cargo clippy --all-targets --locked -- -D warnings
cargo build --release --locked
npm run test:container-identity
npm run test:runtime-policy
npm run test:e2e
```

Everything passed except the final live identity assertion inside
`npm run test:all-claims`. The manifest reached all 27 claims: 26 passed and
`durable-deployment-policy` failed. Untested claim count is zero.

## Next step

Restore the live app to the immutable digest for candidate `8f2956bf…`, prevent
report/Graphify commits from replacing that image, and rerun all 27 declared
claim commands from a clean checkout. A product-code repair is not indicated by
this verification.
