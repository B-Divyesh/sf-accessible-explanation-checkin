# Polish 6 — cumulative finding closure

- Reviewed candidate: `9595291790ab0a928072be63029962e5e0690946`
- Review base: `a98a8e2d06e0b7b84b83196d375f7d1afbbe2bcf`
- Deployed source: `5e7a9644efc483fb226c43cbf024708ef99d91cb`
- Live revision: `sf-accessible-explanation-9c1a54--0000064`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>

Every review and polish record from rounds 1–6 was read. Each finding below
was rechecked against the clean build and the deployed product. The original
classroom-doorway visual system remains unchanged.

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Retained the populated one-click `/demo` and `?demo=1` sandbox, separate `demo:` storage, persistent banner, reset, and start-real controls. Leaving now clears every demo key. | Tests `@claim:demo-isolation`, `@claim:demo-reset`, `@claim:demo-exit-disposal`; screenshot `.factory/evidence/polish-6-live-demo-mobile.png`; live `/?demo=1` passed. |
| F-1-2 | Expanded the claim inventory to 24 entries with exactly one tagged command per claim. | `npm run test:all-claims` passed 24/24 from the clean clone; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live claim audit at `/demo` and the real workflow passed. |
| F-1-3 | Retained the job-first “Collect student reasoning” h1, teacher-specific sentence, sample action, adjacent result, and three facts. | Test `landing and legal screens are semantic and console-clean`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-mobile.png`; cold live `/` passed. |
| F-1-4 | Retained final `USER checkin`, the writable snapshot path, and a runtime execution check under an unprivileged UID. | Test `@claim:runtime-container-policy`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live `/health` reports deployed build `5e7a964`. |
| F-1-5 | Retained destination-h1 focus and polite announcements for link and history navigation. | Test `navigation moves focus to the new heading and updates route metadata`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live `/` → `/create` → back focused each h1. |
| F-1-6 | Retained per-route titles, descriptions, canonicals, Open Graph/Twitter data, icons, theme color, robots, and sitemap. | Test `navigation moves focus to the new heading and updates route metadata`; screenshot `.factory/evidence/polish-6-live-404-mobile.png`; live seven-route metadata audit passed. |
| F-1-7 | Retained the designed unknown-route document with an actual HTTP 404 response. | Test `unknown paths return the designed 404 with an HTTP 404 status`; screenshot `.factory/evidence/polish-6-live-404-mobile.png`; live `/no-such-page` returned 404. |
| F-1-8 | Retained task-naming headings and removed metaphor and slogan copy. | Copy test/audit `.factory/copy-audit.md`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-mobile.png`; cold live `/` copy passed. |
| F-1-9 | Retained landing sentences within the 22-word limit. | Copy test/audit `.factory/copy-audit.md`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-mobile.png`; cold live `/` passed. |
| F-1-10 | Retained precise keyboard wording and complete keyboard-only teacher and student flows. | Tests `@claim:keyboard-demo` and `@claim:student-keyboard-flow`; screenshot `.factory/evidence/polish-6-live-demo-mobile.png`; live `/demo` keyboard controls passed. |
| F-1-11 | Retained “Read the three steps” and its real `#how` destination. | Test `landing and legal screens are semantic and console-clean`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live `/#how` link crawl passed. |
| F-1-12 | Retained the plain README audience sentence. | Copy test/audit `.factory/copy-audit.md`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-mobile.png`; live `/` uses the same plain audience description. |
| F-1-13 | Retained short, reproducible test documentation. | Clean-clone `npm test` in `.factory/evidence/polish-6-clean-clone.json`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live `/health` passed. |
| F-1-14 | Retained the concise durable deployment instructions and required wrapper. | Tests `@claim:durable-deployment-policy` and `@claim:live-durability-checker`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live revision `0000064` passed the durability gate. |
| F-1-15 | Retained concise security guidance backed by response-header checks. | Test `landing and legal screens are semantic and console-clean`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live `/` returned CSP, HSTS, Permissions Policy, no-sniff, and referrer headers. |
| F-2-1 | Kept all public workflow, privacy, plan, runtime, and deployment promises in the 24-entry claim inventory. | `npm run test:all-claims` passed 24/24; screenshot `.factory/evidence/polish-6-live-demo-mobile.png`; live demo, classroom, billing, voice, and deployment checks passed. |
| F-2-2 | Retained the full doorway-styled 404 skeleton with skip link, navigation, metadata, legal links, footer, and mobile treatment. | Test `unknown paths return the designed 404 with an HTTP 404 status`; screenshot `.factory/evidence/polish-6-live-404-mobile.png`; live `/no-such-page` passed Axe and route checks. |
| F-2-3 | Retained task-naming h1 text on setup and plans pages. | Test `landing and legal screens are semantic and console-clean`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live `/create` and `/pricing` h1 assertions passed. |
| F-2-4 | Retained the visible “opens external site” label on the Sociobot checkout. | Test `@claim:external-checkout`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live `/pricing` link label and checkout redirect passed. |
| F-3-1 | Retained the registered $39 one-time Sociobot/Dodo checkout and safe public redirect proof. | Test `@claim:external-checkout`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live catalog returned USD 3900 and checkout returned a Dodo 303. |
| F-3-2 | Retained the exact Playwright pin and committed npm lockfile. | Clean-clone `npm ci` installed 86 packages with zero vulnerabilities; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; the resulting build served live at `/`. |
| F-4-1 | Retained a visible Privacy link in every SPA header and the static 404 header. | Test `every public route keeps Privacy in the primary navigation`; screenshot `.factory/evidence/polish-6-live-404-mobile.png`; all seven live routes passed. |
| F-5-1 | Reapplied the durable wrapper after the generic deploy, pinned one replica, mounted Azure File at `/app/data`, and required cross-revision private-record reads. | Test `@claim:durable-deployment-policy`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live student/review/receipt reads were 24/24 before and after revision replacement. |
| F-5-2 | Retained the fail-fast browser shards and added one fresh-worker retry for a headless-shell process crash; assertion failures still fail after two independent attempts. | Test `playwright configuration keeps the release matrix isolated`; clean-clone `npm run test:e2e` passed 46 tests with 10 intentional device skips; screenshot `.factory/evidence/polish-6-live-demo-mobile.png`; live browser audit passed. |
| F-5-3 | Retained short release-gate sentences and replaced the remaining opaque deployment wording. | Copy test/audit `.factory/copy-audit.md`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live `/health` and the documented gate both passed. |
| F-6-1 | Restored the production topology after deploy: exactly one active/running replica and one Azure File volume mounted at `/app/data`. The gate created a real record and replaced the production revision. | Tests `@claim:durable-deployment-policy` and `scripts/verify-live-durable-workflow.sh`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live revision `0000064` returned 24/24 student, review, and receipt reads before and after replacement. |
| F-6-2 | Added `voice-recording-limits`; the UI timer stops recording at 120 seconds, the server accepts exactly 4 MiB, and 4 MiB plus one byte returns the stated 413 error. | Test `@claim:voice-recording-limits`; screenshot `.factory/evidence/polish-6-live-demo-mobile.png`; live voice audit repeated 120000 ms, 4194304-byte acceptance, and 4194305-byte rejection. |
| F-6-3 | Added `teacher-voice-deletion`; deletion removes the file and voice metadata while preserving text, receipt, tags, note, and follow-up state. | Test `routes::tests::claim_teacher_voice_deletion`; screenshot `.factory/evidence/polish-6-live-demo-mobile.png`; live API audit returned 410 for audio and retained the text receipt and review. |
| F-6-4 | Clearing demo mode now removes every `demo:` key before any non-demo route renders. Returning to demo loads the shipped seed. | Test `@claim:demo-exit-disposal`; screenshot `.factory/evidence/polish-6-live-demo-mobile.png`; live `/?demo=1` → `/create` → `/demo` passed. |
| F-6-5 | Replaced “topology and this failure gate” with the concrete storage-mount, one-replica, and private-link checks. | Copy test/audit `.factory/copy-audit.md`; screenshot `.factory/evidence/polish-6-verify-home/screenshot-desktop.png`; live deployment output proved each named check. |

## Final evidence

- Clean clone `/tmp/aec-polish6-final.PrzYNP/repo` at `0dc87fe`: `npm ci`
  passed with 86 packages and zero vulnerabilities. All 24 claim commands,
  `npm test`, `npm run build`, `npm run test:e2e`, Rust formatting, and Clippy
  with warnings denied passed.
- The build produced `dist/`; JavaScript is 38.93 kB raw and 12.43 kB gzip.
  CSS is 19.30 kB raw and 5.16 kB gzip.
- Factory `verify-url.sh` passed with one h1, `lang=en`, a main landmark,
  complete alt text, and no browser console errors.
- The cold live audit covered seven routes, 14 links, 390 px layout, 200%
  text, light/dark Axe, focus/history, demo isolation/reset/disposal/offline,
  the real classroom flow, exact voice limits, early deletion, billing,
  security headers, and privacy request boundaries.
- A live 150-request burst returned 30 HTTP 429 responses; all 30 included
  `Retry-After`.
- Mobile Lighthouse scored 100 performance, 100 accessibility, 100 best
  practices, and 100 SEO. LCP was 1.050 s, TBT 5 ms, and CLS 0.

Machine-readable receipts and screenshots are under
`.factory/evidence/polish-6-*`. No finding from rounds 1–6 remains unresolved.
