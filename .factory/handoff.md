# Accessible Explanation Check-in — polish 6 handoff

- Work order: `accessible-explanation-checkin-polish-6`
- Reviewed candidate: `9595291790ab0a928072be63029962e5e0690946`
- Repair source deployed: `5e7a9644efc483fb226c43cbf024708ef99d91cb`
- Live revision: `sf-accessible-explanation-9c1a54--0000064`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Completed: 2026-08-29 UTC

## What changed

- Added the missing 120-second and 4 MiB voice-limit claim. The browser timer,
  exact accepted boundary, oversized 413 response, and single accepted record
  are tested.
- Added the missing teacher voice-deletion claim. Its backend test proves the
  audio file and metadata are removed while text, receipt, tags, note, and
  follow-up remain.
- Demo exit now clears every `demo:` storage key. Returning to `/demo` restores
  the shipped sample rather than edited state.
- Replaced the remaining deployment jargon and updated the verb-first catalog
  description.
- Added one fresh-worker Playwright retry for isolated Chromium process
  crashes. The release shards remain serial and fail deterministic assertions.
- Extended the live audit to cover demo disposal, the recording timer, exact
  upload boundaries, and early voice deletion against production.
- Preserved the product-specific classroom doorway, field-note palette, type,
  layout, and motion system.

The complete finding-by-finding map is in `.factory/polish-6.md`. The claim
inventory now contains 24 entries.

## Clean-clone verification

Fresh clone: `/tmp/aec-polish6-final.PrzYNP/repo` at
`0dc87fe3a578a96de0e3451b3aa9811bcf1e33e8`.

| Command | Result |
| --- | --- |
| `npm ci` | Pass: 86 packages, zero vulnerabilities |
| `npm run test:all-claims` | Pass: 24/24 claim commands |
| `npm test` | Pass: 5 Vitest tests, 13 Rust tests, and 2 deployment fixtures |
| `npm run build` | Pass: `dist/` produced; JS 12.43 kB gzip; CSS 5.16 kB gzip |
| `npm run test:e2e` | Pass: 46 tests; 10 intentional device/fixture skips |
| `cargo fmt --all -- --check` | Pass |
| `cargo clippy --all-targets --locked -- -D warnings` | Pass |

Receipt: `.factory/evidence/polish-6-clean-clone.json`.

## Deployment and live verification

Deployed with:

```sh
scripts/deploy-durable-container.sh accessible-explanation-checkin /work/repo Dockerfile 8080
```

The wrapper created revision `0000063`, applied the durable topology, then
forced a real replacement to revision `0000064`. The final Azure state has:

- `minReplicas = 1` and `maxReplicas = 1`;
- one active, healthy revision and one running replica;
- Azure File storage `aec-accessible-explanati-9c1a54` mounted at `/app/data`;
- `/health` build SHA `5e7a9644efc483fb226c43cbf024708ef99d91cb`.

The deployment gate got 24/24 HTTP 200 reads for the new student, review, and
receipt URLs before replacement. It repeated all three at 24/24 afterward and
confirmed the submission and saved teacher review persisted.

Post-deploy checks:

- `npm run audit:live`: pass. Seven routes, real 404 status, 14 crawled links,
  titles, metadata, focus/history announcements, 390 px touch targets, 200%
  text, light/dark Axe, zero serious or critical findings, and zero console
  errors.
- Demo: pass at `/?demo=1`. Three records load in one click; edits stay in the
  `demo:` namespace; reset, full exit disposal, and offline reload work.
- Real workflow: pass. Create, student submission, receipt, teacher review,
  saved review reload, and same-origin privacy boundary work.
- Voice: pass. The live UI scheduled exactly 120000 ms; 4194304 decoded bytes
  were accepted; 4194305 were rejected with 413. Early deletion returned 410
  for audio while retaining text, receipt, and teacher review fields.
- Checkout: pass. Public catalog price is USD 39 and checkout returns a 303 to
  `checkout.dodopayments.com`.
- Factory `verify-url.sh`: pass with title, `lang=en`, one h1, main landmark,
  alt text, and no console errors.
- Rate limiting: pass. A 150-request burst returned 30 HTTP 429 responses, all
  with `Retry-After`.
- Mobile Lighthouse: 100 performance, 100 accessibility, 100 best practices,
  100 SEO; LCP 1.050 s, TBT 5 ms, CLS 0, total transfer 39,081 bytes.

Evidence: `.factory/evidence/polish-6-live-check.json`,
`.factory/evidence/polish-6-live-durability.json`,
`.factory/evidence/polish-6-live-topology.json`,
`.factory/evidence/polish-6-rate-limit.json`,
`.factory/evidence/polish-6-lighthouse-mobile.json`, and the
`.factory/evidence/polish-6-*` screenshots.

## Run and deploy

```sh
npm ci
npm test
npm run test:all-claims
npm run build
npm run test:e2e
```

Always deploy with `scripts/deploy-durable-container.sh`; a generic container
deploy temporarily recreates the unsafe stateless scaling template.

## Known gaps and next steps

None. All findings from reviews 1–6, including every minor finding and each
reopened issue, are closed and verified on the live deployment.
