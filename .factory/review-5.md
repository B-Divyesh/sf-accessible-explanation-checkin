# Adversarial first-read review 5 — FAIL

- Product: Accessible Explanation Check-in
- Reviewed: 2026-08-29 UTC
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Repository revision: `d28bd7579540f81628e11b384c142ac692cebccb`
- Live build: `976328637bdfe5cdec53afa4e4303882351ef760`

## Verdict

**FAIL.** The landing page and demo pass the 30-second first-read test, but the
real workflow does not reliably preserve or return private records. A fresh
student link returned false 404 responses on 13 of 24 independent reads. The
corresponding review and receipt each returned 12 false 404s out of 24. Public
privacy, refund, storage, and moderation promises also remain outside the claim
inventory, reopening F-2-1. A PASS requires zero findings and no untested claim.

## Cold first screen

I opened the live root in fresh Chromium contexts at 390 × 844 and 1440 × 900
without scrolling.

- **What it does:** collects a student's reasoning in text or voice and gives
  the teacher a review.
- **For whom:** teachers who need a low-stakes explanation check-in after
  classwork.
- **What to click first:** **Try it with sample data**. The adjacent result says
  “Open a populated teacher review; nothing is saved.”

The first screen answers all three questions at both widths. The h1 is
“Collect student reasoning”; the teacher sentence, sample action, outcome, and
three facts are visible at 390 px. There is no horizontal overflow, console
error, or page error. This part is not blocking.

Evidence: `evidence/review-5-live-home-mobile.png` and
`evidence/review-5-live-home-desktop.png`.

## Findings

### F-5-1 — BLOCKING — Real private links intermittently return 404

**Location and exact evidence.** The live `/create` page promises: “You’ll get
separate student and teacher-review links.” The README says: “The deployment
uses one SQLite replica.” On live build
`976328637bdfe5cdec53afa4e4303882351ef760`, I created a new check-in and used
24 independent, non-keepalive connections for each private URL:

| Private resource | 200 | 404 |
| --- | ---: | ---: |
| Student link | 11 | 13 |
| Teacher review after a successful submission | 12 | 12 |
| Student receipt | 12 | 12 |

The submission itself returned 201. The same record then existed for only some
requests. This independently reproduces verification 6 and the failing
addendum in the prior handoff. The normal browser audit passed only because its
single connection stayed on one backend.

**Why this fails.** A student can receive an invalid-link error for a valid
teacher-issued URL. A teacher can miss submitted work, and a student can lose
access to the receipt. This breaks the central job-to-be-done and contradicts
the one-replica deployment claim.

**Concrete fix.** Make the live service converge to exactly one active and one
running backend with the same Azure File share mounted at `/app/data`, or move
the records to a shared transactional database. Before release, create one
real check-in, require 24/24 student, review, and receipt reads over new
connections, replace the production revision, then require 24/24 again. Make
that live boundary check a deployment gate rather than relying only on mocked
Azure and HTTP fixtures.

Evidence: `evidence/review-5-live-durability.json`.

### F-2-1 — BLOCKING — Public claims are still outside the claim inventory

This earlier blocking finding is only partially fixed. The 18 listed claims
all pass, but the following live statements have no matching `claims.json`
entry and observable test. Some are broader than the implementation proves.

| Location and exact quote | Gap | Concrete fix |
| --- | --- | --- |
| `/create`: “We store only the fields shown on this form.” | The database also stores generated IDs, random student/review tokens, timestamps, and response limits. The absolute “only” statement is inaccurate and untested. | Replace it with “Creating a check-in stores these form fields, random private-link tokens, limits, and timestamps.” Add a database-schema claim test, or remove the storage summary and link to Privacy. |
| `/create`, recent links: “Saved only in this browser.” | No listed claim checks where the recent-review list is stored or what happens in a fresh browser. | Add a claim that creates a check-in, verifies the recent-link key in localStorage, verifies a fresh context has no list, and records requests. |
| `/pricing`: “It handles checkout and refund requests on its site.” `/privacy`: “Sociobot/Dodo handles Classroom Plus checkout, license verification, and refunds.” `/terms`: “Sociobot/Dodo is the merchant of record and handles checkout and refunds.” | `external-checkout` proves the catalog price and checkout redirect. `billing-license-fixture` proves valid/revoked UI states. Neither exercises a refund request or proves who handles it. | Use the tested sentence “Checkout opens on Sociobot/Dodo.” Remove refund claims, or add a safe recorded refund-state contract test through the Sociobot billing API. |
| `/privacy`: “Text remains until the school or teacher requests deletion.” and “EU and UK users may request access, correction, or erasure through their teacher or the service contact.” | No listed claim exercises a correction/deletion request or confirms that it is completed. | Provide and test a real request workflow, or rewrite these as contact instructions without promising an unverified outcome. |
| `/privacy`: “The application and SQLite database run on Sociobot infrastructure.” | No claim entry verifies the live hosting boundary. The existing deployment-policy test uses mocked Azure responses, and the live topology currently contradicts the intended deployment. | Remove the infrastructure sentence until deployment is verified, or add a release check against the actual control plane and live service. |
| `/terms`: “We may limit abusive traffic and remove unlawful records.” | A non-claim unit test covers a local rate limiter. Nothing in `claims.json` covers traffic limiting, and no test covers record removal. | Split the sentence. Inventory and test the rate-limit behavior if it remains public; remove the record-removal promise unless there is an observable administrative workflow. |
| `/terms`: “Material changes will update the effective date.” | This is a process promise with no claim entry or test. | Remove it from factual product copy, or add a release policy check that requires an effective-date change when legal content changes. |

**Why this blocks acceptance.** Teachers and schools can rely on these
statements when deciding how student data is stored, deleted, and purchased.
Passing tests for a different checkout or UI behavior does not test these
promises. This is the same incomplete-inventory failure identified in review
2, so it remains blocking under the history rule.

### F-5-2 — HIGH — The documented full E2E command is not reliable

**Location and exact quote.** README run block: `npm run test:e2e`.

**Evidence.** From the clean clone, the command completed 37 assertions, then
Chromium headless-shell received `SIGSEGV` while starting the mobile
`@claim:demo-reset` case. Final result: 37 passed, 8 skipped, 1 failed. The
same demo-reset claim passed in its required isolated command, and all 18 claim
commands passed individually. The prior handoff documents the same combined
runner crash.

**Why this fails.** A documented verification command does not complete
reliably from a clean checkout. A maintainer cannot distinguish a product
regression from runner instability without rerunning individual cases.

**Concrete fix.** Change `test:e2e` to execute stable desktop and mobile shards
in separate browser processes, or otherwise remove the Chromium lifecycle
crash. Keep the command fail-fast for real assertion failures and verify it in
a fresh clone before documenting it.

### F-5-3 — MEDIUM — A README sentence exceeds 22 words

**Location and exact quote.** README line 39, 24 words: “It finishes only after
repeated cross-connection private-link reads, a student submission, a saved
teacher review, and replacement by a new production revision all pass.”

**Why this fails.** The sentence combines four separate release checks. It is
harder to scan and exceeds the plain-words hard cap.

**Concrete rewrite.** “The deployment gate checks private links, submission,
and teacher review. It repeats those checks after replacing the production
revision.” Do not retain the statement until F-5-1 is true in production.

## Copy audit

Counts are whitespace-delimited. Headings, actions, facts, and footer lines are
included because they are read independently. “Flag” is empty where the text
passes the plain-words checks.

### Landing page

| Words | Text | Flag |
| ---: | --- | --- |
| 5 | Student explanation check-ins for teachers | — |
| 3 | Collect student reasoning | — |
| 15 | For teachers who need a low-stakes check-in, students explain one choice by text or voice. | — |
| 5 | Try it with sample data | — |
| 8 | Open a populated teacher review; nothing is saved. | — |
| 4 | Read the three steps | — |
| 2 | No accounts | — |
| 5 | Voice deletes on your schedule | — |
| 5 | Free check-ins accept 35 responses | — |
| 4 | What a teacher receives | — |
| 4 | How the check-in works | — |
| 9 | Review a student’s explanation, confidence, and optional voice note. | — |
| 7 | Use them to plan a follow-up conversation. | — |
| 3 | Create one check-in | — |
| 8 | Ask one question about a choice or step. | — |
| 4 | Students explain their reasoning | — |
| 9 | Students can complete the form using only a keyboard. | — |
| 3 | Review each explanation | — |
| 8 | Save tags and notes for your next conversation. | — |
| 6 | What this tool does not do | — |
| 11 | It does not grade, detect AI use, proctor, or verify identity. | — |
| 2 | Privacy limits | — |
| 6 | Voice deletes on the selected schedule. | — |
| 5 | Keep private review links secure. | — |
| 5 | Student explanation check-ins for teachers. | — |
| 6 | No automated grading or identity checks. | — |
| 8 | Original generated classroom art · Param Factory, 2026 | — |
| 7 | Built by Param Factory · version 1.0.0 | — |

No landing sentence exceeds 22 words. No landing heading is a metaphor or
mood slogan. The two actions use result-naming verbs, terminology is
consistent, and no banned marketing adjective appears.

### README

| Words | Text | Flag |
| ---: | --- | --- |
| 3 | Accessible Explanation Check-in | — |
| 12 | Collect student reasoning with a low-stakes text or voice check-in for teachers. | — |
| 13 | Teachers use it when they want students to explain a choice after classwork. | — |
| 2 | Try it | — |
| 7 | Open `/demo` for a populated teacher review. | — |
| 10 | The demo saves edits only in a separate browser key. | — |
| 7 | Use **Reset demo** to restore the sample. | — |
| 9 | Use **Start for real** to create a private check-in. | — |
| 3 | Run and test | — |
| 10 | Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain. | — |
| 11 | `npm run test:all-claims` reads `.factory/claims.json` and runs every listed command separately. | — |
| 6 | It stops at the first failure. | — |
| 9 | The app listens on `PORT` and defaults to `8080`. | — |
| 6 | Its frontend build is in `dist/`. | — |
| 9 | Local records use `data/` unless configuration supplies another path. | — |
| 1 | Deploy | — |
| 8 | This is a single-container Rust and Vite application. | — |
| 6 | Build it with the root `Dockerfile`. | — |
| 10 | The image declares port 8080 and the non-root `checkin` user. | — |
| 11 | Its claim test executes the release server under an unprivileged UID. | — |
| 5 | Use `scripts/deploy-durable-container.sh` for Container Apps. | — |
| 9 | It mounts a product-specific Azure File share at `/app/data`. | — |
| 6 | The deployment uses one SQLite replica. | false live; F-5-1 |
| 24 | It finishes only after repeated cross-connection private-link reads, a student submission, a saved teacher review, and replacement by a new production revision all pass. | over 22 words; F-5-3; false live |
| 10 | The deployment-policy claim tests the topology and this failure gate. | fixture-only evidence; F-5-1 |
| 9 | See privacy, terms, demo notes, and the MIT license. | — |

No README heading is metaphorical, no term changes name, and no banned
marketing adjective appears. F-5-3 is the sole sentence-length flag.

### Terminology

| Concept | One term used |
| --- | --- |
| Teacher-created activity | check-in |
| Student response | explanation |
| Teacher workspace | review |
| Student record | receipt |

## Demo and sandbox

- The first-screen action opens `/demo` in one click.
- The first demo screen already shows the “Watershed reasoning” teacher review
  with three realistic student explanations, confidence values, review tags,
  teacher notes, and follow-up state.
- The persistent banner says “Demo — sample data, nothing is saved” and has
  **Reset demo** and **Start for real**.
- Editing and saving wrote only
  `demo:accessible-explanation-checkin:review`; `recent-checkins` remained
  absent in the fresh context. Reset restored Maya Chen’s shipped note.
- No `/api/` request occurred during demo edit, save, reset, or export. All
  demo assets were same-origin. Offline reload succeeded after the first visit.
- The sample CSV had one header and all three sample responses.

The demo therefore passes its one-click, realistic-data, reset, isolation,
privacy-request, and offline checks. No CLI or library sandbox applies.

## Claims

I cloned repository revision `d28bd75` to
`/tmp/tmp.5iFoXZyBGx/repo`, ran `npm ci`, then ran every command listed in
`.factory/claims.json` through `npm run test:all-claims`.

| Claim id | Result |
| --- | --- |
| `demo-isolation` | PASS |
| `demo-reset` | PASS |
| `sample-csv-export` | PASS |
| `keyboard-demo` | PASS |
| `offline-demo` | PASS |
| `no-account-needed` | PASS |
| `voice-retention-control` | PASS |
| `voice-retention-deletion` | PASS |
| `free-response-limit` | PASS |
| `no-automated-judgment` | PASS |
| `student-keyboard-flow` | PASS |
| `student-review-workflow` | PASS |
| `privacy-request-boundary` | PASS |
| `classroom-plus-limits` | PASS |
| `billing-license-fixture` | PASS |
| `external-checkout` | PASS |
| `runtime-container-policy` | PASS |
| `durable-deployment-policy` | PASS locally; production contradicts it (F-5-1) |

No listed command failed. F-2-1 records the public claims that are not listed.
The durability command passes mocked Azure and HTTP controls; it does not
cancel the observed live failure.

## Structure, accessibility, privacy, and links

- `/`, `/demo`, `/create`, `/pricing`, `/privacy`, and `/terms` return 200;
  `/no-such-page` returns the designed HTTP 404.
- Every checked route has `lang=en`, one h1, one main, a route-specific title
  no longer than 60 characters, description, canonical, OG/Twitter metadata,
  SVG favicon, Apple-touch icon, shared header/footer, Privacy, and Terms.
- `robots.txt`, `sitemap.xml`, the manifest, social image, doorway icon, and
  Apple-touch icon return 200. The sitemap lists every public SPA route.
- Back/forward navigation focuses the destination h1 and updates the polite
  route announcer.
- The crawl found 14 unique links. Internal links returned 2xx/3xx, mail links
  were explicit, and the labeled external $39 checkout returned 303 to Dodo.
- At 390 px in light and dark modes, all public routes and the 404 had no
  serious/critical Axe findings, undersized interactive targets, or horizontal
  overflow. The 200% text check passed.
- The live request log for the demo and classroom flow used only the product
  origin. No model, analytics, advertising, remote-font, or third-party-script
  request appeared. The checkout was tested separately after explicit action.
- `verify-url.sh` passed live `/` and `/demo`: correct title, language, h1,
  main, image alt text, button names, and no console errors.
- The classroom-at-blue-hour art, doorway mark, paper/chalk palette, and
  field-notebook controls form a distinct product identity. This is not a
  generic SaaS card/gradient template.

Evidence: `evidence/review-5-live-check.json`, the `review-5-live-home/` and
`review-5-live-demo/` directories, and the review-5 screenshots.

## Earlier-finding verification

Every earlier `review-*.md`, `polish-*.md`, and handoff was read. Each prior
review finding was checked in the live site and current source rather than
accepted from its closure note.

| Earlier finding | Current result |
| --- | --- |
| F-1-1 | Fixed: populated one-click demo, separate `demo:` storage, banner, reset, and start-real action all work. |
| F-1-2 | Fixed as originally stated: a claim inventory and observable tagged tests now exist; completeness is separately reopened as F-2-1. |
| F-1-3 | Fixed: job, teacher audience, first action, and action result are visible before scrolling. |
| F-1-4 | Fixed in source/local runtime: final image policy is non-root and the unprivileged write test passes. |
| F-1-5 | Fixed: route and history navigation focus and announce the h1. |
| F-1-6 | Fixed: route metadata, social data, canonical links, and icons are complete, including 404. |
| F-1-7 | Fixed: unknown routes return the designed document with HTTP 404. |
| F-1-8 | Fixed: landing headings name tasks and limits. |
| F-1-9 | Fixed: no landing sentence exceeds 22 words. |
| F-1-10 | Fixed: keyboard wording is precise and tested. |
| F-1-11 | Fixed: **Read the three steps** names and reaches its result. |
| F-1-12 | Fixed: README audience wording is plain. |
| F-1-13 | Fixed for `npm ci`, `npm test`, and claims; the separate full-E2E reliability issue is F-5-2. |
| F-1-14 | Fixed: the Container Apps instruction is concise. |
| F-1-15 | Fixed: the overloaded security sentence is absent. |
| F-2-1 | **BLOCKING, still partial:** 18 claims are tested, but the live statements listed above remain unlisted. |
| F-2-2 | Fixed: 404 has shared navigation/footer, legal links, metadata, icon, and visual identity. |
| F-2-3 | Fixed: create and pricing h1s name their tasks. |
| F-2-4 | Fixed: purchase action names Sociobot and says it opens an external site. |
| F-3-1 | Fixed: live checkout returns a Dodo session redirect. |
| F-3-2 | Fixed: lockfile exists and `npm ci` succeeds in a clean clone. |
| F-4-1 | Fixed: Privacy is visible in primary navigation on every public route and the 404. |

The unnumbered critical persistence finding in the latest handoff addendum and
verification 6 is **not fixed**; it is reproduced as F-5-1.

## Quality-gate evidence

From the clean clone:

| Command | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages, 0 vulnerabilities |
| `npm run test:all-claims` | PASS — all 18 commands |
| `npm test` | PASS — 5 Vitest, 11 Rust, deployment and durability fixtures |
| `npm run build` | PASS — `dist/`; JS 12.48 kB gzip, CSS 5.16 kB gzip |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |
| `npm run test:e2e` | FAIL — Chromium process segfault after 37 passes; 8 skipped; F-5-2 |

## Missed leverage

No missed-leverage finding is recorded. The brief explicitly rejects automated
misconduct inference, so an AI judgement step would conflict with the product.
The useful implied outputs already exist: CSV export and a printable/PDF
receipt. Cross-device sync would expand the current private-link and
data-minimization model rather than complete an obvious missing step.

## What would make this perfect

Make every live private record return consistently before and after a real
revision replacement. Remove or test every remaining public privacy, storage,
refund, hosting, and moderation claim. Make the documented full E2E command
finish reliably, and split the 24-word README sentence. Then rerun this entire
cold-read, demo-isolation, claim, history, routing, accessibility, privacy,
link, and independent-connection audit against the deployed build. Nothing
short of zero findings is a PASS.
