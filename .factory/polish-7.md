# Polish 7 — cumulative finding closure

## Result

**PASS.** Every report from rounds 1–7 and every prior polish record was read.
The repaired application source is `f886c6fc58113551d1efc52d438cc399bbfa8366`.
It was built, deployed, and checked cold at
`https://accessible-explanation-checkin.sociobot.in` before this record was
written. The durable topology result is saved in
[`evidence/polish-7-live-topology.json`](evidence/polish-7-live-topology.json).

## Finding map

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Kept the populated, one-click `/demo` and `?demo=1` sandbox, its isolated `demo:` namespace, persistent banner, reset, and start-real control. | `@claim:demo-isolation`, `@claim:demo-reset`, `@claim:demo-exit-disposal`; live `/?demo=1`; [`polish-7-live-demo-mobile.png`](evidence/polish-7-live-demo-mobile.png). |
| F-1-2 | Kept a complete claims inventory and expanded it to 26 entries with one observable command per public promise. | `npm run test:all-claims` passed from a clean clone; [`claims.json`](claims.json). |
| F-1-3 | Kept the job-first teacher heading, audience sentence, sample action, stated outcome, and three plain facts on the first screen. | [`copy-audit.md`](copy-audit.md); cold live `/`; [`polish-7-live-demo-mobile.png`](evidence/polish-7-live-demo-mobile.png). |
| F-1-4 | Kept the non-root `checkin` container runtime and its writable durable-data policy. | `@claim:runtime-container-policy`; `npm run test:container-identity`; live `/health`. |
| F-1-5 | Kept h1 focus and polite route announcements for links and browser history. | Browser test `navigation moves focus to the new heading and updates route metadata`; live-audit focus result in [`polish-7-live-check.json`](evidence/polish-7-live-check.json). |
| F-1-6 | Kept route-specific title, description, canonical, Open Graph, Twitter, icon, and theme metadata. | Browser metadata test; live `/`, `/create`, `/privacy`, and `/no-such-page`; [`polish-7-verify-url`](evidence/polish-7-verify-url). |
| F-1-7 | Kept the product-styled HTTP 404 with shared navigation, legal links, and mobile layout. | Browser 404 test; cold live `/no-such-page`; [`polish-7-live-404-mobile.png`](evidence/polish-7-live-404-mobile.png). |
| F-1-8 | Kept task-naming headings and removed decorative slogan copy. | [`copy-audit.md`](copy-audit.md); live `/`. |
| F-1-9 | Kept landing copy at or below 22 words per sentence. | [`copy-audit.md`](copy-audit.md); live `/`. |
| F-1-10 | Kept precise keyboard wording and a keyboard-only student workflow. | `@claim:student-keyboard-flow`, `@claim:keyboard-demo`; live `/demo`. |
| F-1-11 | Kept the result-naming “Read the three steps” link and real `#how` destination. | Browser landing test; live `/#how`. |
| F-1-12 | Kept a plain-language README audience and task description. | [`../README.md`](../README.md); [`copy-audit.md`](copy-audit.md). |
| F-1-13 | Kept reproducible install, test, and build instructions. | Fresh-clone `npm ci`, `npm test`, and `npm run build` passed. |
| F-1-14 | Kept concise durable-deployment instructions and the live topology gate. | `@claim:durable-deployment-policy`; [`polish-7-live-topology.json`](evidence/polish-7-live-topology.json). |
| F-1-15 | Kept concise security guidance and response-header checks. | `npm run test:container-identity`; live header checks in [`polish-7-live-check.json`](evidence/polish-7-live-check.json). |
| F-2-1 | Implemented teacher-confirmed whole-check-in deletion. It removes the check-in, every response and receipt link, and all associated voice files; copy now names the teacher action accurately. Added the inventory entry and a real database/file deletion test. | `@claim:teacher-checkin-deletion`; browser test `teacher can confirm deletion of a complete check-in`; live-audit deletion result (`404` for student, review, and receipt links). |
| F-2-2 | Kept the complete 404 skeleton, metadata, skip link, legal links, footer, and mobile treatment. | Browser 404 test; [`polish-7-live-404-mobile.png`](evidence/polish-7-live-404-mobile.png); live `/no-such-page`. |
| F-2-3 | Kept task-naming h1s on setup and pricing routes. | Browser route test; live `/create` and `/pricing`. |
| F-2-4 | Kept the checkout label identifying the external Sociobot destination. | `@claim:external-checkout`; live `/pricing`. |
| F-3-1 | Kept the registered one-time Sociobot/Dodo checkout and safe redirect proof. | `@claim:external-checkout`; live audit recorded a `303` to Dodo. |
| F-3-2 | Kept the lockfile and exact Playwright pin. | Fresh-clone `npm ci` installed 86 packages with zero vulnerabilities; `npm run test:e2e` passed. |
| F-4-1 | Kept Privacy in the shared primary header, including the static 404. | Browser test `every public route keeps Privacy in the primary navigation`; live route crawl. |
| F-5-1 | Kept the durable one-replica, `/data` Azure File deployment and cross-revision private-link gate. | `@claim:durable-deployment-policy`; `npm run verify:live-topology`; live audit workflow result. |
| F-5-2 | Kept the isolated desktop/mobile browser shards and their retry-safe release matrix. | `npm run test:e2e` passed from the clean clone. |
| F-5-3 | Kept short README release-gate sentences. | [`copy-audit.md`](copy-audit.md); [`../README.md`](../README.md). |
| F-6-1 | Deployed the repaired source with the durable wrapper and verified the exact live build identity, active revision, single running replica, and `/data` mount. | `npm run verify:live-topology`; [`polish-7-live-topology.json`](evidence/polish-7-live-topology.json); live `/health` reported `f886c6fc58113551d1efc52d438cc399bbfa8366`. |
| F-6-2 | Kept the listed 120-second / 4 MiB voice limits and server rejection of 4 MiB plus one byte. | `@claim:voice-recording-limits`; live audit voice result. |
| F-6-3 | Kept early teacher voice deletion while preserving text and review state. | `routes::tests::claim_teacher_voice_deletion`; live audit voice deletion result. |
| F-6-4 | Kept exit disposal: leaving demo removes every `demo:` key before a real-data route renders. | `@claim:demo-exit-disposal`; live `/?demo=1` → `/create` → `/demo`. |
| F-6-5 | Kept concrete README wording for the storage mount, replica, and private-link deployment checks. | [`copy-audit.md`](copy-audit.md); [`../README.md`](../README.md). |
| F-7-1 | Replaced the 27-word deployment sentence with the required three short sentences: “One app copy uses a local SQLite database. Each save copies the database and voice upload to `/data`. The next app version restores those files.” | [`../README.md`](../README.md); [`copy-audit.md`](copy-audit.md). |

## Verification

- Fresh clone: `npm ci`, then `npm run test:all-claims` (26/26 observable
  claim commands) passed.
- Local: `npm test`, `npm run build`, `npm run test:e2e`,
  `npm run test:container-identity`, `cargo fmt --all -- --check`,
  `cargo clippy --all-targets --locked -- -D warnings`, and
  `cargo build --release --locked` passed.
- Live, cold: all public routes and the 404 passed metadata, link, console,
  focus, demo isolation, privacy-boundary, workflow, deletion, voice, header,
  and checkout checks. See [`polish-7-live-check.json`](evidence/polish-7-live-check.json).
- Accessibility: `verify-url.sh` passed with one h1, main landmark, English
  language, title, no missing image alt, no unlabeled buttons, and no console
  errors. Axe found zero serious or critical violations on all audited routes.
  See [`polish-7-verify-url`](evidence/polish-7-verify-url).
- Mobile Lighthouse: Performance 100, Accessibility 100, Best Practices 100,
  SEO 100. See [`polish-7-lighthouse-mobile.json`](evidence/polish-7-lighthouse-mobile.json).

No finding from rounds 1–7 remains unresolved.
