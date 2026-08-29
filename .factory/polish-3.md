# Polish 3 — cumulative finding closure

Reviewed release candidate: `b22fa22778cdbb54cc6ffa7530e179bec1716327`.

All findings in reviews 1–3 and all earlier polish records were re-read. The
evidence below maps every finding to an implemented change and an observable
check. The deployed audit target is
<https://accessible-explanation-checkin.sociobot.in>.

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Kept `/demo` and `/?demo=1` as one-click, populated sample routes. Demo edits use only `demo:accessible-explanation-checkin:review`; the banner includes reset and start-real controls. | `@claim:demo-isolation`, `@claim:demo-reset`; `.factory/evidence/polish-3-live-demo-cold-mobile.png`; live `/?demo=1`; `.factory/evidence/polish-3-live-check.json`. |
| F-1-2 | Kept the complete 18-entry claim inventory and strengthened checkout proof against the public billing service. | Every command in `.factory/claims.json` passed individually from clean clone `/tmp/tmp.kdTNlYkusU/repo`; full claim suite: 21 passed, 7 expected mobile skips. |
| F-1-3 | Kept the job-first “Collect student reasoning” screen, teacher-specific sentence, sample action, outcome, and three tested facts. | `@claim:demo-isolation`; `.factory/copy-audit.md`; `.factory/evidence/polish-3-live-home/screenshot-mobile.png`; live `/`. |
| F-1-4 | Kept the final image on `USER checkin`; fixed production Azure Files snapshots to stream bytes without the unsupported SMB chmod operation. | `npm run test:runtime-policy`; Rust test `durable_snapshot_replaces_bytes_without_copying_posix_permissions`; live create/submit/review in `polish-3-live-check.json`. |
| F-1-5 | Kept h1 focus and polite route announcements for link and history navigation. | Browser test `navigation moves focus to the new heading and updates route metadata`; live audit `focus.forward/back = h1`. |
| F-1-6 | Kept route-specific titles, descriptions, canonicals, OG/Twitter data, favicons, and social art on all routes. | Browser metadata tests; live audit covers `/`, `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, and 404. |
| F-1-7 | Kept a styled standalone error document with an actual HTTP 404 response. | Browser test `unknown paths return the designed 404 with an HTTP 404 status`; live `/no-such-page`; `.factory/evidence/polish-3-live-404-mobile.png`. |
| F-1-8 | Kept task-naming landing headings and removed metaphor/slogan copy. | `.factory/copy-audit.md`; live home screenshot. |
| F-1-9 | Kept the long landing thought split into two short sentences. | `.factory/copy-audit.md`; live `/`. |
| F-1-10 | Kept the precise, tested keyboard statement. | `@claim:student-keyboard-flow`; live `/`. |
| F-1-11 | Kept “Read the three steps” and its real `#how` destination. | Live link crawl in `polish-3-live-check.json`; browser landing test. |
| F-1-12 | Kept the plain README audience sentence. | `README.md`; `.factory/copy-audit.md`. |
| F-1-13 | Kept the concise test explanation and complete claim-suite command. | `README.md`; clean-clone `npm test`. |
| F-1-14 | Kept the short durable deployment instructions. | `README.md`; `@claim:durable-deployment-policy`. |
| F-1-15 | Kept concise security guidance; the server supplies the documented headers. | `README.md`; live header assertions in `polish-3-live-check.json`. |
| F-2-1 | Kept all 18 public claims inventoried. Tests cover student keyboard submission, review persistence, receipt/print/CSV, retention deletion, 35/500 limits, revoked licenses, request origins, non-root runtime, and durable deployment. | Every `.factory/claims.json` command passed individually in the clean clone; `npm run test:claims` passed 21 checks with 7 intentional single-fixture/mobile skips. |
| F-2-2 | Kept the 404 in the same doorway visual system and completed its skip link, header/footer, legal links, metadata, icons, and mobile layout. Added a 44 px wordmark target and release identity. | Browser 404 test; live `/no-such-page`; `.factory/evidence/polish-3-live-404-mobile.png`. |
| F-2-3 | Kept “Create a student explanation check-in” and “Plans and prices.” | Live route h1 assertions in `polish-3-live-check.json`. |
| F-2-4 | Kept “Buy Classroom Plus through Sociobot (opens external site)” as the visible and accessible label. | `@claim:external-checkout`; live link-label crawl. |
| F-3-1 | Registered the live $39 one-time Classroom Plus product with Sociobot/Dodo and replaced intercept-only proof with a public catalog assertion plus a safe, unpaid GET that must return a Dodo session redirect. | `@claim:external-checkout`; live response `303` to `checkout.dodopayments.com`; live audit checkout block. |
| F-3-2 | Retained the committed lockfile, pinned Playwright to exactly `1.58.2`, and verified the documented install in a new clone. | Clean clone `/tmp/tmp.kdTNlYkusU/repo`: `npm ci` installed 86 packages with zero vulnerabilities; all following gates passed. |

## Additional acceptance work

- Added a mobile regression test across every public route and the real 404.
  It rejects any visible interactive target below 44 × 44 CSS pixels.
- Enlarged the collapsed wordmark, inline links, and review-tag targets while
  retaining the original classroom doorway and field-notebook visual system.
- Added the required builder/version line to the shared application and 404
  footers.
- The first cold deployment exposed an Azure Files-only `EPERM` after database
  writes. The snapshot implementation no longer copies POSIX permissions to
  SMB; it streams, flushes, and syncs bytes. A permission-preservation unit
  test and a live create → submit → review → reload check cover the repair.
- Added `npm run audit:live` for the repeatable live route, mobile, axe,
  focus, demo, offline, workflow, link, checkout, and security-header audit.

## Verification evidence

- Clean clone `npm ci`: pass, 86 packages, 0 vulnerabilities.
- Clean clone `npm test`: pass, 4 frontend unit tests, 11 Rust tests, and the
  durable deployment policy.
- Clean clone `npm run build`: pass; `dist/` contains 12.47 kB gzip JavaScript
  and 5.16 kB gzip CSS.
- Clean clone `npm run test:e2e`: 36 passed, 8 intentional skips.
- Clean clone `npm run test:claims`: 21 passed, 7 intentional skips.
- Every one of the 18 claim commands: pass when executed individually.
- `npm run test:all-claims` provides the same fail-fast inventory runner for
  later clean-clone verification.
- `cargo fmt --check` and `cargo clippy --all-targets --locked -- -D warnings`:
  pass.
- Live audit: seven routes, 14 crawled links, light/dark axe, 200% text,
  390 px touch targets, focus, isolated resettable demo, offline reload, real
  workflow, security headers, and checkout all pass with no console errors.
- Live Lighthouse mobile: performance 100, accessibility 100, best practices
  100, SEO 100; LCP 1.05 s, TBT 13 ms, CLS 0.
- Screenshots and machine-readable output are under
  `.factory/evidence/polish-3-*`.

No review finding remains unresolved.
