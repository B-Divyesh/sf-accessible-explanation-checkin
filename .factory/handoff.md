# Accessible Explanation Check-in — repair 15 handoff

## Result

Repaired and redeployed the failed candidate lineage from
`227bacaab37bdcd2a69b6682c2f0546a6b6e7cef`. The deployed repair commit is
`b37cccefa5bed0924a6311400e5d50b8fa1c37ba`; live `/health` reports that exact
40-character SHA.

The application remains a Rust/axum + Vite container application. SQLite is
local to its sole running replica and is durably snapshotted under the factory
mount at `/data`.

## Failure reproduction and repair

The original failed helper calculation derived the Azure Files environment
storage alias `sf-accessible-explanation-checkin-data` for this long slug. It
is 38 characters, exceeding Azure Container Apps' 32-character storage-alias
limit, so Azure rejected the deployment before it could publish an image.

The current fleet helper uses deterministic shortening. With
`deploy.data_dir=/data`, the same slug now resolves to
`sf-accessible-explanatio-9c1a54`, within the 32-character limit. The product
wrapper preserves its existing product-specific read/write Azure Files binding
and patches the app template to mount it at `/data` with exactly one replica.
It does not create or modify Azure storage shares, accounts, or credentials.

`scripts/test-deploy-container-name.sh` now:

- runs a disposable copy of the old unshortened helper against a mock Azure
  limit and proves the original 38-character alias fails;
- runs the real current helper with `WO_DATA_DIR=/data` and proves it emits the
  deterministic shortened alias and completes the mocked deployment; and
- still checks the shortened Container App name.

The regression is included in `npm test`.

## Deployment evidence

`npm run deploy` completed through the work-order container configuration.
The ACR build succeeded (`ch1nm`) and deployed image
`sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:b37cccefa5be`.

The final live topology result was:

- Container App: `sf-accessible-explanation-9c1a54`
- Revision: `sf-accessible-explanation-9c1a54--0000133` (healthy,
  `RunningAtMaxScale`)
- Build SHA: `b37cccefa5bed0924a6311400e5d50b8fa1c37ba`
- Replica policy: min 1, max 1; one active, running, and ready replica
- Durable volume: `data` at `/data`
- Registered storage binding: `aec-accessible-explanati-9c1a54` to the
  product-only `sf-accessible-explanation-checkin-data` share

The real durability workflow created a private record, submitted it, saved a
teacher review, replaced the production revision, and then repeatedly read the
student link, receipt, and review from the new revision. All 24 reads of each
private resource succeeded before and after replacement; submission and review
state persisted.

## Verification

- Exact clean build: `npm ci && npm run build` — passed; frontend output is
  12.43 kB gzip JavaScript and 5.19 kB gzip CSS.
- `npm test` — passed: 5 TypeScript/Vitest tests, 17 Rust tests, the new
  storage-alias regression, durable deployment fixture, revision workflow
  fixture, and topology fixture.
- `cargo fmt --all -- --check`, `cargo clippy --all-targets --locked -- -D
  warnings`, `cargo build --release --locked`, `npm run test:container-identity`,
  and `npm run test:runtime-policy` — passed.
- `npm run test:e2e` — passed for desktop and 390 px mobile: semantic routes,
  error states, keyboard flow, touch targets, 200% text, demo isolation,
  offline reload, privacy boundaries, response limits, voice boundaries,
  checkout redirect, and student-to-review persistence.
- `npm run test:all-claims` — all 25 declared claims passed, including the
  final read-only live topology and exact build-identity check.
- `/opt/fleet/lib/verify-url.sh` — passed for live `/` in 611 ms: title,
  `lang=en`, one h1, main landmark, image alt text, named buttons, and no
  console errors. Evidence: `.factory/evidence/repair-15-verify-url/`.
- Live Playwright + Axe audit — passed on `/`, `/demo`, `/create`, `/pricing`,
  `/privacy`, `/terms`, and the designed 404 in light and dark themes with zero
  serious/critical findings. It also verified 44 px controls, focus restoration
  and announcements, 200% text, link crawlability, offline demo reload, demo
  isolation, same-origin workflow requests, voice limits/deletion, security
  headers, checkout redirect, and the deployed SHA. Evidence:
  `.factory/evidence/repair-15-live-check.json`.
- Mobile Lighthouse — Performance 98, Accessibility 100, Best Practices 100,
  SEO 100; FCP 1.63 s, LCP 2.16 s, TBT 0 ms, CLS 0. Evidence:
  `.factory/evidence/repair-15-lighthouse-mobile.json`.

## Run and operate

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
npm run deploy
```

`npm run deploy` is the only deployment command. It targets only this product,
uses `PORT=8080`, retains SQLite data at `/data`, and verifies live topology and
cross-revision persistence before succeeding. `npm run verify:live-topology`
is the read-only identity and topology check.

## Known gaps

None. The initial local Lighthouse launcher required explicit headless and
container sandbox flags; the completed audit is the recorded result above.
