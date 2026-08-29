# Adversarial first-read review 6 — FAIL

- Product: Accessible Explanation Check-in
- Reviewed: 2026-08-29 UTC
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Repository revision: `9595291790ab0a928072be63029962e5e0690946`
- Live build: `483d53c459b569633ce8682503b76447aee4fe19`

## Verdict

**FAIL.** The landing page is clear and the sample demo is immediately usable,
but the real student workflow is unreliable again. A newly created student
link returned 404 on 12 of 24 independent reads, while its paired review link
returned 404 on 11 of 24. Azure also reports no durable volume and allows up to
three replicas. This reopens the earlier private-record durability failure.

Two public voice behaviors remain outside the claim inventory. Demo edits also
survive leaving demo mode, contrary to the required sandbox lifecycle. The
README has one jargon-heavy verification sentence. A PASS requires zero
findings and no untested claim.

## Cold first screen

I opened the live root in fresh Chromium contexts at 390 × 844 and 1440 × 900
without scrolling.

- **What it does:** collects a student's reasoning in text or voice and gives
  the teacher a review.
- **For whom:** teachers who need a low-stakes check-in after classwork.
- **What to click first:** **Try it with sample data**. The adjacent result is
  “Open a populated teacher review; nothing is saved.”

All three answers are explicit at both widths. The h1, audience sentence,
primary action, action result, and three facts are visible at 390 px. There is
no horizontal overflow, console error, or page error. This gate passes.

Evidence: `evidence/review-6-live-home-mobile.png` and
`evidence/review-6-live-home-desktop.png`.

## Findings

### F-6-1 — BLOCKING — Real private links are split across non-durable live storage

**Regression of:** F-5-1.

**Location and exact claim.** README: “It mounts a product-specific Azure File
share at `/app/data`.” and “The deployment uses one SQLite replica.” The create
page says: “You’ll get separate student and teacher-review links.”

**Evidence.** A fresh check-in was read 24 times per private URL using separate
non-keepalive requests:

| Private resource | HTTP 200 | HTTP 404 |
| --- | ---: | ---: |
| Student link | 12 | 12 |
| Teacher review link | 13 | 11 |

A second reproduction created 12 check-ins. In a fresh request context, all 12
review links returned 200, but all 12 paired student links and student
submissions returned 404. The failure is therefore visible in the real job,
not merely inferred from configuration.

The Azure control plane reports revision `0000061`, `minReplicas: 1`,
`maxReplicas: 3`, and `null` for both volumes and volume mounts. It showed one
running replica at the instant inspected, but the allowed scale and absent
`/app/data` mount contradict the documented one-writer durable topology. The
local `durable-deployment-policy` command passes because it uses mocked Azure
and HTTP controls; it does not prove the current deployment.

**Why this fails.** A student can receive a false invalid-link page for a valid
teacher-issued URL or fail to submit. A teacher can intermittently lose access
to the same check-in. New replicas or a revision replacement have no mounted
shared snapshot.

**Concrete fix.** Deploy only through `scripts/deploy-durable-container.sh`.
Require `minReplicas = maxReplicas = 1`, one active and running revision, and an
Azure File volume mounted at `/app/data`. Make the release gate query the real
control plane, then require 24/24 student, review, and receipt reads before and
after a real revision replacement. Prevent the generic deployment path from
overwriting this topology.

Evidence: `evidence/review-6-live-topology.json` and
`evidence/review-6-live-durability.json`.

### F-6-2 — HIGH — The quantitative voice limits are unlisted claims

**Location and exact quote.** Student form: “Nothing recorded. Maximum 2
minutes / 4 MB.”

**Why this fails.** Neither `2 minutes` nor `4 MB` appears as a claim in
`.factory/claims.json`. Source contains a 120-second client timer and a 4 MB
server check, but no tagged claim test verifies either boundary. A student may
rely on both numbers before recording.

**Concrete fix.** Add a `voice-recording-limits` claim. Test that recording
stops at 120 seconds with a controlled clock, that a payload at the supported
size succeeds, and that a payload over 4 MB receives the stated actionable
error. Remove the numbers if they cannot be tested reliably.

### F-6-3 — HIGH — Early teacher voice deletion is an unlisted claim

**Locations and exact quotes.** Student form: “Your teacher can delete it
sooner.” Privacy: “Teachers can delete voice sooner.” Teacher review action:
**Delete voice now**.

**Why this fails.** No claim entry covers teacher-initiated voice deletion.
The untagged `complete_free_checkin_flow` unit test calls the endpoint but only
checks its response status; it does not prove that the file and database voice
fields are gone while text remains. The listed retention-deletion claim covers
scheduled expiry only.

**Concrete fix.** Add a `teacher-voice-deletion` claim and one tagged backend
or browser test. Create a response with voice, delete it through the teacher
review, then assert that the audio request is gone, voice metadata is cleared,
and the text, receipt, and teacher review remain.

### F-6-4 — MEDIUM — Leaving the demo does not discard edited sample state

**Location and exact action.** Demo banner: **Start for real**.

**Evidence.** I changed Maya Chen’s private note to “Persistence probe,” saved
it, and selected **Start for real**. On `/create`, the
`demo:accessible-explanation-checkin:review` key still existed. Returning to
`/demo` restored “Persistence probe” rather than the shipped note.

**Why this fails.** The demo remains isolated from real storage, so real data
is untouched. However, the attached demo-sandbox contract also requires demo
data to be discarded when the visitor leaves demo mode, unless an explicit
one-time keep action is offered.

**Concrete fix.** Clear every `demo:` key when **Start for real** is activated
and when navigation leaves demo mode. Add a claim test that edits the sample,
leaves for `/create`, returns to `/demo`, and observes the shipped seed.

### F-6-5 — LOW — README uses opaque deployment jargon

**Location and exact quote.** README: “The deployment-policy claim tests the
topology and this failure gate.”

**Why this fails.** “Topology” and “failure gate” do not tell a maintainer what
the command checks. The sentence also reads as stronger assurance than the
mock-only test provides while F-6-1 is live.

**Concrete rewrite.** “The deployment test checks the storage mount, the
one-replica setting, and repeated private-link reads.” Keep the live release
check documented separately after F-6-1 is fixed.

## Copy audit

Counts are whitespace-delimited. Headings, actions, facts, and footer lines are
included because they are read independently.

### Landing page

| Words | Text | Result |
| ---: | --- | --- |
| 5 | Student explanation check-ins for teachers | clear audience label |
| 3 | Collect student reasoning | clear job-first h1 |
| 15 | For teachers who need a low-stakes check-in, students explain one choice by text or voice. | clear audience and result |
| 5 | Try it with sample data | result-naming action |
| 8 | Open a populated teacher review; nothing is saved. | clear demo result |
| 4 | Read the three steps | result-naming action |
| 2 | No accounts | listed claim |
| 5 | Voice deletes on your schedule | listed claim |
| 5 | Free check-ins accept 35 responses | listed claim |
| 4 | What a teacher receives | informative label |
| 4 | How the check-in works | informative heading |
| 9 | Review a student’s explanation, confidence, and optional voice note. | listed workflow claim |
| 7 | Use them to plan a follow-up conversation. | usable outcome |
| 3 | Create one check-in | task heading |
| 8 | Ask one question about a choice or step. | instruction |
| 4 | Students explain their reasoning | task heading |
| 9 | Students can complete the form using only a keyboard. | listed keyboard claim |
| 3 | Review each explanation | task heading |
| 8 | Save tags and notes for your next conversation. | listed workflow claim |
| 6 | What this tool does not do | informative heading |
| 11 | It does not grade, detect AI use, proctor, or verify identity. | listed limit |
| 2 | Privacy limits | informative heading |
| 6 | Voice deletes on the selected schedule. | listed retention claim |
| 5 | Keep private review links secure. | instruction |
| 5 | Student explanation check-ins for teachers. | clear footer description |
| 6 | No automated grading or identity checks. | listed limit |
| 8 | Original generated classroom art · Param Factory, 2026 | useful provenance |
| 7 | Built by Param Factory · version 1.0.0 | release identity |

No landing item exceeds 22 words. No landing heading is a metaphor or slogan,
no banned marketing adjective appears, terminology is consistent, and both
actions name their result.

### README

| Words | Text | Result |
| ---: | --- | --- |
| 3 | Accessible Explanation Check-in | product name |
| 12 | Collect student reasoning with a low-stakes text or voice check-in for teachers. | clear summary |
| 13 | Teachers use it when they want students to explain a choice after classwork. | clear audience and situation |
| 2 | Try it | clear heading |
| 7 | Open `/demo` for a populated teacher review. | clear instruction |
| 10 | The demo saves edits only in a separate browser key. | listed isolation claim |
| 7 | Use **Reset demo** to restore the sample. | clear instruction |
| 9 | Use **Start for real** to create a private check-in. | clear instruction |
| 3 | Run and test | clear heading |
| 10 | Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain. | operator requirement |
| 11 | `npm run test:all-claims` reads `.factory/claims.json` and runs every listed command separately. | verified instruction |
| 6 | It stops at the first failure. | verified instruction |
| 9 | The app listens on `PORT` and defaults to `8080`. | listed runtime claim |
| 6 | Its frontend build is in `dist/`. | verified build result |
| 9 | Local records use `data/` unless configuration supplies another path. | operator detail |
| 1 | Deploy | clear heading |
| 8 | This is a single-container Rust and Vite application. | technical description |
| 6 | Build it with the root `Dockerfile`. | clear instruction |
| 10 | The image declares port 8080 and the non-root `checkin` user. | listed runtime claim |
| 11 | Its claim test executes the release server under an unprivileged UID. | listed runtime evidence |
| 5 | Use `scripts/deploy-durable-container.sh` for Container Apps. | clear instruction |
| 9 | It mounts a product-specific Azure File share at `/app/data`. | false live; F-6-1 |
| 6 | The deployment uses one SQLite replica. | false live; F-6-1 |
| 10 | The deployment gate checks private links, submission, and teacher review. | clear, but contradicted live by F-6-1 |
| 9 | It repeats those checks after replacing the production revision. | clear, but contradicted live by F-6-1 |
| 10 | The deployment-policy claim tests the topology and this failure gate. | jargon; F-6-5 |
| 9 | See privacy, terms, demo notes, and the MIT license. | clear links |

No README item exceeds 22 words and no banned marketing adjective appears.
F-6-5 is the sole wording flag; F-6-1 identifies the false live deployment
statements.

### Terminology

| Concept | Term used |
| --- | --- |
| Teacher-created activity | check-in |
| Student response | explanation |
| Teacher workspace | review |
| Student record | receipt |

## Demo and sandbox

- The first-screen action enters `/demo` in one click.
- The first demo screen already shows the “Watershed reasoning” review, three
  realistic explanations, confidence values, tags, notes, and follow-up state.
- The persistent banner says “Demo — sample data, nothing is saved” and shows
  **Reset demo** and **Start for real**.
- Demo editing, saving, reset, CSV export, and offline reload worked. The CSV
  contained its header and all three sample responses.
- Demo activity made no `/api/` request. It wrote only
  `demo:accessible-explanation-checkin:review`; `recent-checkins` stayed absent.
- F-6-4 records the remaining lifecycle failure after leaving demo mode.

Evidence: `evidence/review-6-live-demo-mobile.png` and
`evidence/review-6-live-check.json`.

## Claims

I cloned revision `9595291` without shared build artifacts into
`/tmp/aec-review6.BvQYAn/repo`, ran `npm ci`, and executed every command in
`.factory/claims.json` through `npm run test:all-claims`.

| Claim id | Listed command | Live cross-check |
| --- | --- | --- |
| `demo-isolation` | PASS | PASS |
| `demo-reset` | PASS | PASS |
| `sample-csv-export` | PASS | PASS |
| `keyboard-demo` | PASS | PASS |
| `offline-demo` | PASS | PASS |
| `no-account-needed` | PASS | FAIL intermittently after creation; F-6-1 |
| `stored-record-shape` | PASS | storage is not durable; F-6-1 |
| `recent-links-local` | PASS | PASS |
| `voice-retention-control` | PASS | PASS |
| `voice-retention-deletion` | PASS | PASS for scheduled deletion |
| `free-response-limit` | PASS | not separately load-tested live |
| `no-automated-judgment` | PASS | PASS |
| `student-keyboard-flow` | PASS | blocked intermittently by F-6-1 |
| `student-review-workflow` | PASS | blocked intermittently by F-6-1 |
| `privacy-request-boundary` | PASS | PASS; requests stayed same-origin |
| `classroom-plus-limits` | PASS | fixture-backed |
| `billing-license-fixture` | PASS | fixture-backed |
| `refund-license-contract` | PASS | recorded refunded verdict |
| `external-checkout` | PASS | PASS; live 303 to Dodo checkout |
| `runtime-container-policy` | PASS | live build identity matches |
| `durable-deployment-policy` | PASS against mocks | **FAIL live; F-6-1** |

All 21 listed commands completed. That does not override the direct live
contradiction. F-6-2 and F-6-3 list public behaviors missing from the inventory.

## Structure, accessibility, privacy, and links

- `/`, `/demo`, `/create`, `/pricing`, `/privacy`, and `/terms` returned 200;
  `/no-such-page` returned the designed 404.
- Every checked route had `lang=en`, one h1, one main, a route-specific title,
  description, canonical URL, OG/Twitter metadata, favicon, consistent header
  and footer, Privacy, and Terms.
- The 14-link crawl found no dead internal links. The labeled external checkout
  returned 303 to `checkout.dodopayments.com`.
- Link and back navigation focused and announced the destination h1.
- At 390 px in light and dark modes, all routes had zero serious or critical
  Axe findings, undersized targets, or horizontal overflow. The 200% text check
  passed. Reduced motion was requested during the route audit.
- The factory URL verifier passed with one h1, `lang=en`, a main landmark, alt
  text, named buttons, and no console errors.
- Demo and classroom request logs were product-origin-only. No model,
  analytics, advertising, remote-font, or third-party-script request appeared.
- The blue-hour classroom, doorway mark, paper/chalk palette, and field-notebook
  controls remain distinct from a generic SaaS template.

## Earlier-finding verification

Every earlier `review-*.md`, `polish-*.md`, and handoff was read. Each review
finding was checked in current source and live behavior.

| Earlier finding | Current result |
| --- | --- |
| F-1-1 | Fixed: the populated, isolated one-click demo, banner, reset, and real-start action remain. F-6-4 is a narrower exit-lifecycle gap. |
| F-1-2 | Regressed in completeness: the inventory runs, but F-6-2 and F-6-3 identify unlisted voice claims. |
| F-1-3 | Fixed: job, teacher audience, first action, and result are visible before scrolling. |
| F-1-4 | Fixed in source and the non-root runtime test. |
| F-1-5 | Fixed: link and history navigation focus and announce the h1. |
| F-1-6 | Fixed: route and static-404 metadata are complete. |
| F-1-7 | Fixed: unknown paths return the designed HTTP 404. |
| F-1-8 | Fixed: landing headings name tasks and limits. |
| F-1-9 | Fixed: no landing sentence exceeds 22 words. |
| F-1-10 | Fixed: keyboard wording is specific and tested. |
| F-1-11 | Fixed: **Read the three steps** reaches `#how`. |
| F-1-12 | Fixed: README audience wording is plain. |
| F-1-13 | Fixed: clean `npm ci`, tests, and build pass. |
| F-1-14 | Fixed: the deployment instruction is short. |
| F-1-15 | Fixed: the overloaded security sentence remains absent. |
| F-2-1 | Reopened by F-6-2 and F-6-3: two voice behaviors remain outside the claim inventory. |
| F-2-2 | Fixed: the 404 has the shared skeleton, metadata, legal links, and product identity. |
| F-2-3 | Fixed: create and pricing h1s name their tasks. |
| F-2-4 | Fixed: checkout identifies Sociobot and the external destination. |
| F-3-1 | Fixed: live checkout returns a Dodo session redirect. |
| F-3-2 | Fixed: the lockfile exists and `npm ci` passes from a clean clone. |
| F-4-1 | Fixed: Privacy is visible in every primary header, including 404. |
| F-5-1 | **Regressed and BLOCKING:** see F-6-1. |
| F-5-2 | Fixed: the sharded `npm run test:e2e` completed successfully. |
| F-5-3 | Fixed: the long README sentence remains split. |

## Quality-gate evidence

From `/tmp/aec-review6.BvQYAn/repo`:

| Command | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages, 0 vulnerabilities |
| `npm run test:all-claims` | PASS — 21/21 listed commands |
| `npm test` | PASS — 5 Vitest, 12 Rust, and deployment fixtures |
| `npm run build` | PASS — `dist/`; JS 12.31 kB gzip, CSS 5.16 kB gzip |
| `npm run test:e2e` | PASS — 43 passed, 9 intentional device skips |
| `cargo fmt --all -- --check` | PASS |
| `cargo clippy --all-targets --locked -- -D warnings` | PASS |

## Missed leverage

No additional AI, import, export, or sync feature is indicated. Automated
judgement would conflict with the brief. CSV export and printable receipts
already cover the obvious portable outputs; cross-device sync would broaden
the private-link and data-minimization model rather than complete the core job.

## What would make this perfect

Restore and lock the live one-replica Azure File topology, then prove every
private resource before and after revision replacement. Inventory and test the
voice limits and early-deletion behavior. Clear demo state when leaving the
sandbox, and replace the README jargon. Rerun the complete review against the
new deployment; nothing less than zero findings is a PASS.
