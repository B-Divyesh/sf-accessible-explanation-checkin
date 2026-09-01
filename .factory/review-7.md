# Adversarial first-read review 7 — FAIL

- Product: Accessible Explanation Check-in
- Reviewed: 2026-09-01 UTC
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Repository revision: `57c84d7710ee2045483f3ec539d2d60a2f3f164d`

## Verdict

**FAIL.** The product is clear, immediately tryable, and accessible in the
checked paths. One listed deployment claim fails from a clean clone because the
live image is not this repository revision. One earlier claim-inventory finding
has also regressed: the student flow promises whole-record deletion even though
the product provides only voice deletion and no matching claim. The README has
one 27-word, technical deployment sentence. A PASS requires zero findings.

## Cold first screen

I opened the live root in fresh browser contexts at 390 × 844 and 1440 × 900,
without scrolling.

- **What it does:** collects a student's reasoning by text or voice and gives
  the teacher a review.
- **For whom:** teachers who need a low-stakes check-in after classwork.
- **What to click first:** **Try it with sample data**. The adjacent outcome
  says, “Open a populated teacher review; nothing is saved.”

All three answers are explicit at both sizes. At 390 px, the headline,
audience sentence, primary action, action outcome, and the three plain facts
fit in the first screen. The page had no horizontal overflow or application
console errors. This check passes.

## Findings

### F-6-1 — BLOCKING — The durable-deployment claim fails because the live image is not this revision

**Regression of:** F-6-1.

**Exact failing test.** From a fresh clone at
`57c84d7710ee2045483f3ec539d2d60a2f3f164d`, the listed
`durable-deployment-policy` command ran its fixture, durability, and topology
checks successfully, then failed at `npm run verify:live-topology` with:

```text
ERROR: live topology check failed: image
sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:50cf4e550506
does not identify build 57c84d7710ee
```

The live `/health` response independently reports
`"build_sha":"50cf4e550506809ede10fdfe8330df52b5001bbe"`.

**Why this fails.** The published claim says the deployment check confirms the
live mount, replica, and build identity. The checked deployment does not
identify the repository revision under review, so the release gate cannot
confirm that the reviewed product is the live product. A failing listed claim
is blocking.

**Concrete fix.** Deploy the exact reviewed build, then rerun
`npm run verify:live-topology` from that commit. Keep the claim test strict so
future repository revisions and live image identity cannot diverge unnoticed.

### F-2-1 — BLOCKING — A whole-record deletion promise is unlisted and unavailable

**Regression of:** F-2-1.

**Exact locations.** The creation screen states, “Text remains until the
teacher’s private record is removed from the server.” The student form states,
“You can ask your teacher to delete your record.” The Privacy page directs a
student to ask a teacher to coordinate “access, correction, or deletion.”

**Check.** The public claim inventory has no whole-record deletion claim or
test. The checked routes expose only `DELETE
/api/reviews/:token/submissions/:id/voice` in
[`src/routes.rs`](/work/repo/src/routes.rs:62); the corresponding UI action is
**Delete voice now**. Repository search found no check-in, response, receipt,
or teacher whole-record deletion route or control. `teacher-voice-deletion`
confirms that text and the receipt remain after voice deletion, so it cannot
confirm the stated whole-record result.

**Why this fails.** A student can reasonably expect their teacher to be able
to remove the private record after making that request. The current product
does not provide that outcome or a test that verifies it.

**Concrete fix.** Either implement an authenticated teacher **Delete
check-in** action that removes the check-in, responses, receipt access, and
voice files, then add one isolated claim test for the complete result; or
remove the promise. If removal is handled outside the product, use: “Text is
not on the voice schedule. Ask your school how to request access, correction,
or deletion.” Do not state that a teacher can delete a record unless the
teacher view provides and tests that action.

### F-7-1 — MINOR — README deployment copy is 27 words and contains unexplained deployment terms

**Location and exact quote.** README, Deploy: “SQLite runs locally inside the
one replica; each saved change copies its database snapshot and any voice
upload to `/data`, which is restored on the next revision.”

**Why this needs revision.** The sentence exceeds the 22-word limit and makes
the deployment behavior harder to scan by combining the replica, snapshot, and
revision details.

**Concrete rewrite.** “One app copy uses a local SQLite database. Each save
copies the database and voice upload to `/data`. The next app version restores
those files.”

## Copy audit

Counts are whitespace-delimited. Headings and actions are included because a
screen reader presents them independently. “Claim” identifies text that is
covered by a named entry in `.factory/claims.json`; the deletion wording is
reported in F-2-1.

### Landing page

| Words | Text | Check |
| ---: | --- | --- |
| 5 | Student explanation check-ins for teachers | clear audience label |
| 3 | Collect student reasoning | job-first h1 |
| 15 | For teachers who need a low-stakes check-in, students explain one choice by text or voice. | clear audience and outcome |
| 5 | Try it with sample data | result-naming action |
| 8 | Open a populated teacher review; nothing is saved. | demo claim |
| 4 | Read the three steps | result-naming action |
| 2 | No accounts | claim |
| 5 | Voice deletes on your schedule | claim |
| 5 | Free check-ins accept 35 responses | claim |
| 4 | What a teacher receives | informative label |
| 4 | How the check-in works | informative heading |
| 9 | Review a student’s explanation, confidence, and optional voice note. | workflow claim |
| 7 | Use them to plan a follow-up conversation. | plain outcome |
| 3 | Create one check-in | task heading |
| 8 | Ask one question about a choice or step. | plain instruction |
| 4 | Students explain their reasoning | task heading |
| 9 | Students can complete the form using only a keyboard. | keyboard claim |
| 3 | Review each explanation | task heading |
| 8 | Save tags and notes for your next conversation. | workflow claim |
| 6 | What this tool does not do | informative heading |
| 11 | It does not grade, detect AI use, proctor, or verify identity. | limits claim |
| 2 | Privacy limits | informative heading |
| 6 | Voice deletes on the selected schedule. | retention claim |
| 5 | Keep private review links secure. | plain instruction |
| 5 | Student explanation check-ins for teachers. | footer description |
| 6 | No automated grading or identity checks. | limits claim |
| 8 | Original generated classroom art · Param Factory, 2026 | provenance |
| 7 | Built by Param Factory · version 1.0.0 | build identity |

The landing page has no sentence over 22 words, no non-informational heading,
no slogan, no inconsistent product term, and no non-result action.

### README

| Words | Text | Check |
| ---: | --- | --- |
| 3 | Accessible Explanation Check-in | product title |
| 12 | Collect student reasoning with a low-stakes text or voice check-in for teachers. | clear summary |
| 13 | Teachers use it when they want students to explain a choice after classwork. | clear audience |
| 2 | Try it | informative heading |
| 7 | Open `/demo` for a populated teacher review. | demo instruction |
| 10 | The demo saves edits only in a separate browser key. | demo-isolation claim |
| 7 | Use Reset demo to restore the sample. | demo-reset claim |
| 11 | Start for real discards sample edits before creating a private check-in. | demo-exit-disposal claim |
| 3 | Run and test | informative heading |
| 10 | Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain. | setup requirement |
| 11 | `npm run test:all-claims` reads `.factory/claims.json` and runs every listed command separately. | test instruction |
| 6 | It stops at the first failure. | test instruction |
| 9 | The app listens on `PORT` and defaults to `8080`. | runtime claim |
| 6 | Its frontend build is in `dist/`. | build instruction |
| 9 | Local records use `data/` unless configuration supplies another path. | operator detail |
| 1 | Deploy | informative heading |
| 8 | This is a single-container Rust and Vite application. | deployment description |
| 6 | Build it with the root `Dockerfile`. | deployment instruction |
| 10 | The image declares port 8080 and the non-root `checkin` user. | runtime claim |
| 11 | Its claim test executes the release server under an unprivileged UID. | runtime-test detail |
| 6 | Run `npm run deploy` for Container Apps. | deployment instruction |
| 14 | It mounts the factory-registered, product-specific Azure File share at the work order's `/data` path. | deployment claim |
| 27 | SQLite runs locally inside the one replica; each saved change copies its database snapshot and any voice upload to `/data`, which is restored on the next revision. | **F-7-1: long; technical** |
| 6 | The deployment uses one SQLite replica. | deployment claim |
| 10 | The deployment gate checks private links, submission, and teacher review. | deployment claim |
| 9 | It repeats those checks after replacing the production revision. | deployment claim |
| 12 | Run `npm run verify:live-topology` to check the live mount, replica, and build identity. | operator instruction |
| 10 | See privacy, terms, demo notes, and the MIT license. | resource links |

No other README sentence exceeds 22 words. The remaining technical words are
necessary command, runtime, or deployment names in setup instructions. Product
terms remain consistent: **check-in**, **explanation**, **review**, and
**receipt**.

## Demo and privacy checks

- The landing action opened `/demo` in one click. The first screen showed the
  populated **Watershed reasoning** teacher review with three realistic
  explanations, confidence values, review tags, notes, and follow-up state.
- The persistent banner read “Demo — sample data, nothing is saved” and
  provided **Reset demo** and **Start for real**.
- Editing Maya Chen’s sample note created only
  `demo:accessible-explanation-checkin:review`. **Reset demo** restored “Ask
  Maya to connect the model to the class data.” **Start for real** moved to
  `/create` and left browser storage empty.
- The fresh demo request log contained only the product origin’s HTML, JS, and
  CSS. It made no API request and did not create normal check-in storage.

## Claims and quality checks

- A new clone at `57c84d7` completed `npm ci` with 86 packages and no reported
  vulnerabilities. `npm run build` passed and produced `dist/`: JavaScript is
  12.43 kB gzip and CSS is 5.19 kB gzip.
- All 25 claim commands were run through `npm run test:all-claims` from the
  clean-clone setup. The first 24 passed, including the final Playwright result
  of `passed` with no failed tests. The 25th,
  `durable-deployment-policy`, failed at the live build-identity check as
  documented in F-6-1. F-2-1 is not covered by those entries.
- Fresh mobile and desktop checks found one h1, `main`, `lang="en"`, a plain
  title, description, canonical, Open Graph, Twitter card, favicon, and no
  horizontal overflow on the checked public routes. The unknown route returned
  the styled document with HTTP 404.
- Link checks returned 200 for `/`, `/demo`, `/create`, `/pricing`, `/privacy`,
  `/terms`, `robots.txt`, `sitemap.xml`, the manifest, and the social image.
  The external checkout label was explicit and its product URL returned 303 to
  the named external checkout site. Mail links were not fetched.
- On `/` → `/create` → back, focus moved to the destination h1 and the polite
  live region announced the destination. The visible focus outline was present.
- Axe found zero violations on `/`, `/demo`, `/create`, `/pricing`, `/privacy`,
  `/terms`, and the designed 404 at the mobile viewport.
- The classroom doorway art, paper-like surfaces, and restrained colors remain
  distinct from a generic SaaS template. The brief calls for no automated
  judgment; no unnecessary AI feature or embedded provider key was found.

## Earlier finding confirmation

Every earlier review, polish record, and handoff was read. The table records a
current live and code check, not merely the previous status. F-2-1 is the sole
regression.

| Earlier finding | Current check |
| --- | --- |
| F-1-1 | Confirmed: `/demo` and `?demo=1` load the populated isolated sample, show the banner and controls, and use `demo:` storage. |
| F-1-2 | Confirmed: `claims.json` contains 25 uniquely identified commands; F-2-1 identifies the newly unlisted deletion wording. F-6-1 records the separate failing live deployment command. |
| F-1-3 | Confirmed: the first screen has the job-first h1, teacher audience, sample action, stated outcome, and three facts. |
| F-1-4 | Confirmed: Docker/runtime policy remains covered by `runtime-container-policy`; README and source retain the non-root `checkin` user. |
| F-1-5 | Confirmed: current browser navigation and browser back focused each destination h1 and announced it. |
| F-1-6 | Confirmed: current public routes expose route-specific title, description, canonical, Open Graph, Twitter, and icons. |
| F-1-7 | Confirmed: `/no-such-page` returned the designed document with HTTP 404. |
| F-1-8 | Confirmed: landing headings name sections and tasks rather than a mood or metaphor. |
| F-1-9 | Confirmed: every landing sentence is at or below 22 words. |
| F-1-10 | Confirmed: the landing keyboard wording is precise and `student-keyboard-flow` remains listed. |
| F-1-11 | Confirmed: **Read the three steps** reaches the real `#how` section. |
| F-1-12 | Confirmed: README starts with the plain teacher and student task description. |
| F-1-13 | Confirmed: README lists reproducible install, test, and build commands; clean `npm ci` passed. |
| F-1-14 | Confirmed in code: the durable deployment claim and live-topology command remain listed. F-6-1 records the current live build-identity failure. |
| F-1-15 | Confirmed: README deployment guidance names its checks without the prior opaque wording. |
| F-2-1 | **REGRESSED:** the whole-record deletion sentences above have no product action or claim test. |
| F-2-2 | Confirmed: the static 404 retains header, navigation, legal links, metadata, and the doorway visual system. |
| F-2-3 | Confirmed: the current setup and plans h1s name their tasks. |
| F-2-4 | Confirmed: the checkout control states “opens external site.” |
| F-3-1 | Confirmed: the checkout product URL returned a live 303 to the named external checkout site without a payment action. |
| F-3-2 | Confirmed: the tracked lockfile enabled a successful clean `npm ci`. |
| F-4-1 | Confirmed: Privacy is visible in primary navigation on every checked route, including the static 404. |
| F-5-1 | Confirmed in code: the durable deployment claim and documentation retain the `/data` and one-replica checks. F-6-1 records the current live build-identity failure. |
| F-5-2 | Confirmed: the documented browser suite remains split into desktop and mobile application and claim commands. |
| F-5-3 | Confirmed: the earlier README sentence remains split; F-7-1 is a separate current long sentence. |
| F-6-1 | **REGRESSED:** the listed durable deployment command fails because the live image identifies `50cf4e550506`, not the reviewed `57c84d7710ee`. |
| F-6-2 | Confirmed: `voice-recording-limits` is listed and passed. |
| F-6-3 | Confirmed: `teacher-voice-deletion` is listed and passed. |
| F-6-4 | Confirmed directly: leaving demo removed every `demo:` key before `/create`. |
| F-6-5 | Confirmed: README names the mount, replica, and build-identity check; it no longer uses the prior opaque phrase. |

## What would make this perfect

Deploy the exact reviewed build and rerun the live topology claim. Provide and
test a complete teacher-controlled record-deletion path, or remove the current
promise and direct students to their school’s request process. Then split the
one long README deployment sentence and rerun the clean-clone claim runner,
route, demo, accessibility, and copy checks. With those three items complete,
the product would have no remaining finding from this review.
