# Polish 4 — cumulative finding closure

Reviewed candidate: `4d64cc563b09798e80701e427aa5c7df7d8d3da3`.

Every review and earlier polish record was read before this repair. The sole
open issue was F-4-1. Earlier closures below were re-executed rather than
assumed. The final deployment and exact commit are recorded in the handoff.

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Retained the populated, one-click `/demo` and `?demo=1` sandbox, separate `demo:` storage, banner, reset, and start-real action. | `@claim:demo-isolation`, `@claim:demo-reset`; `.factory/evidence/polish-4-live-demo-cold-mobile.png`; live `/?demo=1`. |
| F-1-2 | Retained the complete 18-entry claim inventory and its one-command-per-claim runner. | `npm run test:all-claims` (18 commands); `.factory/claims.json`; clean-clone test output. |
| F-1-3 | Retained the job-first hero, teacher audience sentence, sample action, action outcome, and three tested facts. | `.factory/copy-audit.md`; `.factory/evidence/polish-4-live-demo-cold-mobile.png`; live `/`. |
| F-1-4 | Retained the non-root `checkin` runtime and durable snapshot execution proof. | `@claim:runtime-container-policy`; live `/health`. |
| F-1-5 | Retained destination-h1 focus and polite route announcement for link and history navigation. | Browser test `navigation moves focus to the new heading and updates route metadata`; `.factory/evidence/polish-4-live-check.json`; live `/create`. |
| F-1-6 | Retained route-specific title, description, canonical, Open Graph, Twitter, favicon, and social art metadata. | Browser metadata test; `.factory/evidence/polish-4-live-check.json`; live `/`, `/create`, and `/no-such-page`. |
| F-1-7 | Retained the styled HTTP 404 for unknown routes. | Browser test `unknown paths return the designed 404 with an HTTP 404 status`; `.factory/evidence/polish-4-live-404-mobile.png`; live `/no-such-page`. |
| F-1-8 | Retained task-naming landing headings and removed slogan copy. | `.factory/copy-audit.md`; live `/`. |
| F-1-9 | Retained short landing sentences. | `.factory/copy-audit.md`; live `/`. |
| F-1-10 | Retained precise, tested keyboard wording. | `@claim:student-keyboard-flow`; live `/`. |
| F-1-11 | Retained “Read the three steps” and its real `#how` anchor. | Browser landing check; live `/#how`. |
| F-1-12 | Retained the plain-language README audience description. | `README.md`; `.factory/copy-audit.md`. |
| F-1-13 | Retained concise, reproducible README test instructions. | `README.md`; clean-clone `npm ci` and `npm test`. |
| F-1-14 | Retained concise durable-deployment instructions. | `README.md`; `@claim:durable-deployment-policy`. |
| F-1-15 | Retained concise deployment/security guidance backed by response-header checks. | `README.md`; `.factory/evidence/polish-4-live-check.json`; live `/`. |
| F-2-1 | Retained observable tests for workflow, keyboard use, retention cleanup, quotas, licensing, privacy requests, runtime, and deployment. | `npm run test:all-claims`; `.factory/claims.json`; clean-clone test output. |
| F-2-2 | Retained the complete doorway-styled static 404 with header, skip link, legal links, footer, metadata, icons, and mobile treatment. | Browser 404 test; `.factory/evidence/polish-4-live-404-mobile.png`; live `/no-such-page`. |
| F-2-3 | Retained task-naming route h1s. | Browser route checks; live `/create` and `/pricing`. |
| F-2-4 | Retained the explicit external Sociobot checkout label. | `@claim:external-checkout`; live `/pricing`. |
| F-3-1 | Retained the public $39 Sociobot/Dodo checkout and safe live redirect check. | `@claim:external-checkout`; `.factory/evidence/polish-4-live-check.json`; live `/pricing`. |
| F-3-2 | Retained `package-lock.json` and verified the documented fresh-clone install. | clean-clone `npm ci`, `npm test`, `npm run build`, `npm run test:e2e`, and `npm run test:all-claims`. |
| F-4-1 | Added a visible Privacy link to the shared SPA primary navigation and the static 404 primary navigation. Added a regression across every public route. | Browser test `every public route keeps Privacy in the primary navigation`; `.factory/evidence/polish-4-live-404-mobile.png`; live `/`, `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, and `/no-such-page`. |

## Verification

- `npm test`: 4 frontend unit tests, 11 Rust tests, and deployment-policy test passed.
- `npm run build`: passed; production JavaScript is 12.48 kB gzip and CSS is 5.16 kB gzip.
- `npm run test:e2e`: 38 passed, 8 intentional single-fixture/mobile skips.
- `npm run test:all-claims`: all 18 commands passed independently.
- `cargo fmt --check` and `cargo clippy --all-targets --locked -- -D warnings`: passed.
- The final cold live audit verifies primary Privacy navigation, 390 px targets, 200% text, light/dark axe, routes, 404 status, console, demo isolation/reset/offline reload, workflow persistence, checkout, and headers. Its screenshots and JSON are the `polish-4-live-*` files above.

No review finding remains unresolved.
