# Polish 5 — cumulative finding closure

- Reviewed candidate: `976328637bdfe5cdec53afa4e4303882351ef760`
- Review base: `84766c5177e24971b5596de3eaa3f75e7e9f37d1`
- Repair source: `5aa0519153e7c34d129d37b9aba69d359b960a33`
- Live revision: `sf-accessible-explanation-9c1a54--0000060`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>

Every `.factory/review-*.md` and `.factory/polish-*.md` present at the review
base was read. Earlier fixes were retained and rerun. Review 5's reopened
F-2-1 is closed below with precise copy and three additional claim tests.

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Retained the populated `/demo` and `?demo=1` sandbox. Demo edits use only the `demo:` namespace. The banner includes Reset demo and Start for real. | `@claim:demo-isolation`, `@claim:demo-reset`; `.factory/evidence/polish-5-live-demo-mobile.png`; live `/?demo=1`. |
| F-1-2 | Expanded the complete claim inventory from 18 to 21 entries. The runner executes exactly one tagged command for every entry. | `npm run test:all-claims` passed 21/21 in the clean clone; `.factory/claims.json`; live audit in `.factory/evidence/polish-5-live-check.json`. |
| F-1-3 | Retained the job-first h1, teacher audience sentence, primary sample action, adjacent outcome, and three tested facts above the fold. | `.factory/copy-audit.md`; `.factory/evidence/polish-5-verify-home/screenshot-mobile.png`; live `/`. |
| F-1-4 | Retained the non-root `checkin` runtime, writable durable snapshot path, port default, and build SHA. | `@claim:runtime-container-policy`; `npm run test:container-identity`; live `/health`. |
| F-1-5 | Retained destination-h1 focus and polite announcements for links and browser history. | Browser test `navigation moves focus to the new heading and updates route metadata`; focus section in `.factory/evidence/polish-5-live-check.json`; live `/create`. |
| F-1-6 | Retained route-specific titles, descriptions, canonicals, Open Graph, Twitter, icons, theme color, robots, and sitemap. | Browser metadata test and seven-route live audit; `.factory/evidence/polish-5-live-check.json`; live `/`, `/create`, `/privacy`. |
| F-1-7 | Retained the doorway-styled unknown route with a real HTTP 404, one h1, main landmark, navigation, and legal footer. | Browser test `unknown paths return the designed 404 with an HTTP 404 status`; `.factory/evidence/polish-5-live-404-mobile.png`; live `/no-such-page`. |
| F-1-8 | Retained task-naming landing headings and removed decorative slogans. | `.factory/copy-audit.md`; `.factory/evidence/polish-5-verify-home/screenshot-mobile.png`; live `/`. |
| F-1-9 | Retained first-screen and landing sentences within the 22-word limit. | `.factory/copy-audit.md`; cold screenshot `.factory/evidence/polish-5-verify-home/screenshot-mobile.png`; live `/`. |
| F-1-10 | Retained the exact keyboard claim and complete keyboard submission test. | `@claim:student-keyboard-flow` and `@claim:keyboard-demo`; live `/demo`. |
| F-1-11 | Retained “Read the three steps” and the real `#how` destination. | Browser landing test; `.factory/evidence/polish-5-verify-home/screenshot-desktop.png`; live `/#how`. |
| F-1-12 | Retained the plain audience and task description in the README. | `README.md`; `.factory/copy-audit.md`; live `/`. |
| F-1-13 | Retained reproducible install, test, claim, and build commands. | Clean clone evidence `.factory/evidence/polish-5-clean-clone.json`; `README.md`. |
| F-1-14 | Retained the required durable deployment wrapper and made 24 reads per private resource the live gate. | `@claim:durable-deployment-policy`; `.factory/evidence/polish-5-live-durability.json`; live `/health`. |
| F-1-15 | Retained precise deployment and security guidance backed by response-header and runtime checks. | `npm run test:container-identity`; security headers in `.factory/evidence/polish-5-live-check.json`; live `/`. |
| F-2-1 | Added schema, recent-link locality, and recorded refund claims. Rewrote storage and refund copy to match observable behavior. Removed unproved hosting, record-removal, completed-request, and legal-change promises. | `@claim:stored-record-shape`, `@claim:recent-links-local`, `@claim:refund-license-contract`, `storage and legal copy stays precise and claim-backed`; 21/21 claim commands; live `/create`, `/pricing`, `/privacy`, `/terms`. |
| F-2-2 | Retained the complete product-styled 404 skeleton, metadata, skip link, navigation, legal links, and footer. | Browser 404 test; `.factory/evidence/polish-5-live-404-mobile.png`; live `/no-such-page`. |
| F-2-3 | Retained task-naming h1 text for setup and pricing routes. | Seven-route h1 audit in `.factory/evidence/polish-5-live-check.json`; live `/create` and `/pricing`. |
| F-2-4 | Retained the explicit external-site label on the checkout link. | `@claim:external-checkout`; live `/pricing`. |
| F-3-1 | Retained the public $39 one-time Sociobot/Dodo checkout and verified the live 303 destination. | `@claim:external-checkout`; checkout section in `.factory/evidence/polish-5-live-check.json`; live `/pricing`. |
| F-3-2 | Retained the npm lockfile and verified installation from a clean clone. | `npm ci` passed with zero vulnerabilities in `.factory/evidence/polish-5-clean-clone.json`; `package-lock.json`. |
| F-4-1 | Retained a visible Privacy link in the shared header on every SPA route and the static 404. | Browser test `every public route keeps Privacy in the primary navigation`; seven-route live audit; live `/`, `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, `/no-such-page`. |
| F-5-1 | Deployed through the durable wrapper. Azure now has one active/running replica and one Azure File mount at `/app/data`. The gate read the student link, review link, and receipt 24/24 before replacement and 24/24 afterward. It also recovered the saved review. | `scripts/verify-live-durable-workflow.sh`; `.factory/evidence/polish-5-live-durability.json`; `.factory/evidence/polish-5-live-topology.json`; live `/health`. |
| F-5-2 | Split the combined E2E command into fresh desktop/mobile application and claim shards. It remains fail-fast and avoids the accumulated Chromium lifecycle crash. | `npm run test:e2e` passed from the clean clone: 43 passed and 9 intentional device skips; `frontend/src/playwright-config.test.ts`; `.factory/evidence/polish-5-clean-clone.json`. |
| F-5-3 | Split the 24-word README sentence into three short release-gate statements. | `.factory/copy-audit.md`; `README.md`; `@claim:durable-deployment-policy`. |

## Final verification

- Fresh clone: `/tmp/aec-polish5-receipts.ATYgws/repo` at `5aa0519`.
- `npm ci`: pass, 86 packages and zero vulnerabilities.
- `npm test`: pass, including TypeScript, 5 Vitest tests, 12 Rust tests, and deployment fixtures.
- `npm run build`: pass; `dist/` produced. JavaScript is 38,568 bytes raw and 12,310 bytes gzip. CSS is 19,296 bytes raw and 5,160 bytes gzip.
- `npm run test:e2e`: pass, 43 passed and 9 intentional device skips.
- `npm run test:all-claims`: pass, all 21 commands.
- `cargo fmt --all -- --check` and clippy with `-D warnings`: pass.
- Container identity and deterministic deploy-helper tests: pass.
- Live route, focus, link, demo, offline, workflow, checkout, security-header, mobile, dark-theme, and axe audit: pass.
- Factory `verify-url.sh`: pass with no browser console errors.
- Live 150-request rate burst: 120 normal responses, 30 HTTP 429 responses, and `Retry-After` on every 429.
- Mobile Lighthouse: 100 performance, 100 accessibility, 100 best practices, and 100 SEO; LCP 1.052 s, CLS 0, TBT 0 ms.

No finding from rounds 1–5 remains unresolved.
