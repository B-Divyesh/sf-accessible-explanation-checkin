# Polish 8 — cumulative finding closure

## Result

**PASS.** Every `review-*.md` and `polish-*.md` through round 8 was read.
The repaired product candidate is
`2182c924b7b2a2e1a9ed84f629538989a38aeacd`. That exact build is live at
<https://accessible-explanation-checkin.sociobot.in> on revision
`sf-accessible-explanation-9c1a54--0000146`.

## Finding map

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Kept the populated one-click `/demo` and `?demo=1` sandbox, isolated `demo:` keys, persistent banner, reset, and start-real disposal. | `@claim:demo-isolation`, `@claim:demo-reset`, `@claim:demo-exit-disposal`; live `/?demo=1`; [mobile demo](evidence/polish-8-live-demo-mobile.png). |
| F-1-2 | Expanded the complete claim inventory to 27 entries, each with one observable command. | Clean-clone `npm run test:all-claims`: 27/27 passed; [claims](claims.json). |
| F-1-3 | Kept the job-first heading, teacher audience sentence, sample action with outcome, and three plain facts on the first screen. | [copy audit](copy-audit.md); cold live `/`; [mobile home](evidence/polish-8-verify-home/screenshot-mobile.png). |
| F-1-4 | Kept the non-root `checkin` container and writable durable SQLite snapshot. | `@claim:runtime-container-policy`; ACR container build; live `/health`. |
| F-1-5 | Kept h1 focus and polite announcements on link, back, and forward navigation. | Browser test `navigation moves focus to the new heading and updates route metadata`; [live audit](evidence/polish-8-live-check.json). |
| F-1-6 | Kept route-specific title, description, canonical, social, icon, and theme metadata. | Browser metadata tests; `verify-url.sh`; [live audit](evidence/polish-8-live-check.json). |
| F-1-7 | Kept the product-styled real HTTP 404 with shared skeleton, legal links, and mobile layout. | Browser 404 test; live `/no-such-page`; [mobile 404](evidence/polish-8-live-404-mobile.png). |
| F-1-8 | Kept task-naming headings and removed decorative slogans and brand lore. | [copy audit](copy-audit.md); cold live `/`. |
| F-1-9 | Kept every audited landing sentence at 22 words or fewer. | [copy audit](copy-audit.md). |
| F-1-10 | Kept precise keyboard wording and a complete keyboard-only student flow. | `@claim:student-keyboard-flow`, `@claim:keyboard-demo`; desktop and mobile browser suites. |
| F-1-11 | Kept the result-naming “Read the three steps” link and its real `#how` destination. | Browser landing test; live `/#how`. |
| F-1-12 | Kept the README audience and task description in plain words. | [README](../README.md); [copy audit](copy-audit.md). |
| F-1-13 | Kept reproducible install, test, build, and deploy instructions. | Clean clone: `npm ci`, `npm test`, `npm run build`, and all 27 claim commands passed. |
| F-1-14 | Kept concise durable deployment instructions and a live topology gate. | `@claim:durable-deployment-policy`; [topology](evidence/polish-8-live-topology.json); [durability](evidence/polish-8-live-durability.json). |
| F-1-15 | Kept concise security guidance, response headers, and enforced API throttling. | Rust forwarded-IP rate-limit test; [live headers](evidence/polish-8-live-check.json); [live rate limit](evidence/polish-8-rate-limit.json). |
| F-2-1 | Kept confirmed whole-check-in deletion of responses, receipt links, and voice files. | `@claim:teacher-checkin-deletion`; browser deletion test; live audit records three 404 results after deletion. |
| F-2-2 | Kept the 404 skeleton, metadata, skip link, legal links, footer, and mobile treatment. | Browser 404 test; [mobile 404](evidence/polish-8-live-404-mobile.png). |
| F-2-3 | Kept task-naming h1s on setup and pricing routes. | Browser route tests; live `/create` and `/pricing`. |
| F-2-4 | Kept the checkout label identifying its external Sociobot destination. | `@claim:external-checkout`; live `/pricing`. |
| F-3-1 | Kept the registered $39 one-time Sociobot/Dodo checkout and safe redirect proof. | `@claim:external-checkout`; live audit records HTTP 303 to `checkout.dodopayments.com`. |
| F-3-2 | Kept the lockfile and exact Playwright 1.58.2 pin. | Clean-clone `npm ci`: 86 packages, zero vulnerabilities; `npm run test:e2e`: 52 passed. |
| F-4-1 | Kept Privacy in the primary navigation on every public route, including the static 404. | Browser test `every public route keeps Privacy in the primary navigation`; live route crawl. |
| F-5-1 | Kept the single-replica `/data` Azure File deployment and cross-revision private-record gate. | `@claim:durable-deployment-policy`; [topology](evidence/polish-8-live-topology.json); [durability](evidence/polish-8-live-durability.json). |
| F-5-2 | Kept isolated desktop/mobile browser shards and the retry-safe release matrix. | `npm run test:e2e`: 52 passed, 12 intentional project skips. |
| F-5-3 | Kept short README release-gate sentences. | [README](../README.md); [copy audit](copy-audit.md). |
| F-6-1 | Replaced raw `HEAD` comparison with a tested resolver for the last shipped or acceptance-critical product commit. Review, polish, evidence, and graph-index commits no longer invalidate the deployed candidate. | `scripts/test-product-candidate.sh`; clean-clone `npm run verify:live-topology`; exact live SHA in [topology](evidence/polish-8-live-topology.json). |
| F-6-2 | Kept the public 120-second and 4 MiB voice limits, including rejection at 4 MiB plus one byte. | `@claim:voice-recording-limits`; [live audit](evidence/polish-8-live-check.json). |
| F-6-3 | Kept early teacher voice deletion while preserving text, receipt, tags, note, and follow-up state. | `routes::tests::claim_teacher_voice_deletion`; live audit voice result. |
| F-6-4 | Kept exit disposal so start-real removes every `demo:` key before real-data UI renders. | `@claim:demo-exit-disposal`; live audit demo result. |
| F-6-5 | Kept concrete README wording for the mount, replica, and private-link checks. | [README](../README.md); [copy audit](copy-audit.md). |
| F-7-1 | Kept the three short SQLite persistence sentences introduced in round 7. | [README](../README.md); [copy audit](copy-audit.md). |
| F-8-1 | Added `prompt-character-limit` to the claim inventory and a real browser boundary test: 1,200 characters create a check-in; 1,201 show the server recovery error and focus it. | `@claim:prompt-character-limit`; clean-clone claim runner; [live prompt boundary](evidence/polish-8-live-prompt-limit.json). |
| F-8-2 | Standardized the Terms heading and design thesis on the canonical spelling “judgment.” | Browser legal-copy assertion; live `/terms`; [copy audit](copy-audit.md). |

## Verification

- Clean clone at candidate SHA: `npm ci`, `npm test`, `npm run build`, and
  `npm run test:all-claims` passed; the manifest completed all 27 commands.
- Full local gates: `npm run test:e2e` passed 52 tests with 12 intentional
  project skips; `cargo fmt --all -- --check`, clippy with warnings denied,
  and locked release build passed.
- Cold live audit: seven routes in light and dark themes, real 404, focus and
  announcements, 14 crawled links, demo isolation/reset/disposal/offline,
  classroom workflow, deletion, voice, checkout, security headers, and
  same-origin privacy passed with no console errors. Axe found zero serious or
  critical violations. See [live audit](evidence/polish-8-live-check.json).
- Factory `verify-url.sh` passed on `/` and `/?demo=1`; see
  [home evidence](evidence/polish-8-verify-home/verify.json) and
  [demo evidence](evidence/polish-8-verify-demo/verify.json).
- Mobile Lighthouse: Performance 98, Accessibility 100, Best Practices 100,
  SEO 100; LCP 1.3 s, TBT 170 ms, CLS 0, transferred 39,171 bytes. See
  [Lighthouse evidence](evidence/polish-8-lighthouse-mobile.json).

No finding from rounds 1–8 remains unresolved.
