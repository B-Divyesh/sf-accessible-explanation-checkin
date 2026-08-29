# Accessible Explanation Check-in — repair 6 handoff

## Result: release blocker repaired

- Work order: `accessible-explanation-checkin-repair-6`
- Verifier candidate: `33cc77d99a11d16010227138259a90d5cd24c073`
- Repair implementation: `88e66ea1a0c7ab6b50b682406e021c0baa3101c3`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

Independent verification 8 found one release blocker. Production had
`minReplicas=1`, `maxReplicas=3`, two ephemeral SQLite replicas, and no volume
mount. Fresh student, review, and receipt links returned intermittent `404`s.

The finding was reproduced before repair with the real Azure control plane:
`minReplicas=1`, `maxReplicas=3`, `volumes=null`, and no volume mount. The new
`npm run verify:live-topology` gate rejected that live state with exit 1.

## Repair and regression coverage

- Added `scripts/verify-live-topology.sh`, a read-only release gate against the
  effective Azure configuration and live `/health` identity.
- The gate requires one ready and active revision, one running replica,
  `minReplicas=maxReplicas=1`, the expected read-write Azure File share, its
  `/app/data` mount, the expected image tag, and the full live build SHA.
- Added `scripts/test-live-topology.sh`. Its negative fixture is the verifier's
  exact unmounted 1–3 replica configuration and fails before release.
- Wired the real gate into `scripts/deploy-durable-container.sh` after its
  forced-revision persistence workflow.
- Updated the `durable-deployment-policy` claim so mocks alone cannot pass it;
  the claim now queries the real control plane and deployed identity.
- Kept the original Rust/axum + SQLite backend, Vite frontend, demo, visual
  system, billing boundary, privacy behavior, and all previously passing flows.

## Live durability evidence

The durable deploy built image tag `88e66ea1a0c7`, mounted Azure Files, and
forced a replacement from revision `0000067` to `0000068`.

- Build SHA: `88e66ea1a0c7ab6b50b682406e021c0baa3101c3`
- Storage registration: `aec-accessible-explanati-9c1a54`
- File share: `sf-accessible-explanation-checkin-data`
- Mount: `checkin-data` at `/app/data`
- Scale: minimum 1, maximum 1
- Active revisions: 1
- Running replicas: 1
- Before replacement: student 24/24, review 24/24, receipt 24/24 returned 200
- After replacement: student 24/24, review 24/24, receipt 24/24 returned 200
- The student submission and saved teacher review persisted after replacement.

## Verification completed

- `npm ci`: 86 packages installed; zero reported vulnerabilities.
- `npm test`: TypeScript, 5 Vitest tests, 13 Rust tests, deployment fixtures,
  cross-revision workflow fixture, and the verifier-8 topology regression pass.
- `cargo fmt --all -- --check`: pass.
- `cargo clippy --all-targets --locked -- -D warnings`: pass.
- `npm run build`: pass; `dist/` produced.
- `cargo build --release --locked`: pass.
- Container name, build identity, and non-root runtime checks: pass.
- `npm run test:e2e`: 46 passed; 10 intentional device/fixture skips.
- `npm run test:all-claims`: all 24 claim commands pass, including the real
  production topology and build-identity gate.
- Factory `verify-url.sh`: title, `lang=en`, one h1, main, alt text, labels,
  desktop/mobile screenshots, and zero console errors pass.
- Live audit: seven routes plus the real 404, light and dark themes, 200% text,
  390 px layout, 44 px targets, link crawl, route focus/announcement, and axe
  serious/critical checks pass with zero findings.
- Keyboard-only sample review and student submission pass.
- Privacy check: demo and classroom flows use only the product origin; the demo
  makes no API writes. No analytics, CDN font, or third-party script appears.
- Offline/update: the service worker update completes and the populated demo
  reloads offline at 390 px.
- Response policy: private API JSON returns `Cache-Control: private, no-store`.
  CSP, HSTS, Permissions Policy, `nosniff`, and no-referrer headers are present.
- Rate limit: 150 same-client requests returned 120 normal responses and 30
  `429`s; every `429` included `Retry-After`.
- Live identity: image tag, `/health`, and ready revision identify the repair.
- Mobile Lighthouse: 100 performance, 100 accessibility, 100 best practices,
  100 SEO; LCP 1.080 s, TBT 0 ms, CLS 0, transfer 39,092 bytes.
- Production bundles: 12.43 kB gzip JS and 5.16 kB gzip CSS.

Evidence is in `.factory/evidence/repair-6-live-check.json`,
`.factory/evidence/repair-6-live-demo-mobile.png`,
`.factory/evidence/repair-6-live-404-mobile.png`,
`.factory/evidence/repair-6-verify/`, and
`.factory/evidence/repair-6-lighthouse-mobile.json`.

## Run and verify

```bash
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
npm run audit:live
npm run verify:live-topology
```

Deploy only through:

```bash
scripts/deploy-durable-container.sh accessible-explanation-checkin /work/repo Dockerfile 8080
```

## Known gaps and next steps

No release-blocking product gap remains. A generic stateless Container Apps
deployment can overwrite this topology, so every release must use the durable
wrapper and must pass the real live topology gate before acceptance.
