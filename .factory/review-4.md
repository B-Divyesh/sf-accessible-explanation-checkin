# Adversarial first-read review 4 — FAIL

- Product: Accessible Explanation Check-in
- Reviewed: 2026-08-29 UTC
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Repository revision: `4d64cc563b09798e80701e427aa5c7df7d8d3da3`

## Verdict

**FAIL.** The product is clear, tryable, and its checked promises pass. One
site-structure requirement remains: the shared primary navigation omits
Privacy. A PASS requires no findings.

## Cold first screen

Fresh Chromium contexts at 390 × 844 and 1440 × 900 gave the same answer
before scrolling: it collects a student explanation of reasoning in text or
voice for teachers, and the first action is **Try it with sample data**. The
adjacent outcome says “Open a populated teacher review; nothing is saved.”
The first screen therefore passes the five-second test. Its cold request log
contained only product-origin HTML, self-hosted JS/CSS, and self-hosted art;
there were no console errors.

## Findings

### F-4-1 — MEDIUM — The shared primary navigation omits Privacy

**Location / exact evidence.** The live primary header on `/`, `/demo`,
`/create`, `/pricing`, `/privacy`, `/terms`, and the designed 404 contains
only **Demo**, **Create**, and **Plans**. **Privacy** and **Terms** appear only
in the footer.

**Why this fails.** The required common header includes the wordmark and a
short navigation that includes Privacy. A teacher considering a student-data
check-in should not need to scroll to the footer to reach the privacy policy.

**Concrete fix.** Add a visible **Privacy** link to the shared application
header and `frontend/public/404.html` header. Four links is within the stated
maximum. Add a browser assertion that every public route's primary navigation
includes Privacy.

## Copy audit

Counts are whitespace-delimited. Headings, actions, facts, and footer text are
included because they are read independently. No item exceeds 22 words. No
landing or README item uses banned marketing language, an unexplained metaphor
heading, inconsistent terminology, or a non-result-naming action. The
visitor-facing factual promises map to `.factory/claims.json`.

### Landing page

| # | Words | Text | Result |
| --- | ---: | --- | --- |
| 1 | 5 | Student explanation check-ins for teachers | audience label |
| 2 | 3 | Collect student reasoning | job-first h1 |
| 3 | 15 | For teachers who need a low-stakes check-in, students explain one choice by text or voice. | audience and use |
| 4 | 5 | Try it with sample data | result-naming action |
| 5 | 8 | Open a populated teacher review; nothing is saved. | demo outcome |
| 6 | 4 | Read the three steps | result-naming action |
| 7 | 2 | No accounts | tested fact |
| 8 | 5 | Voice deletes on your schedule | tested fact |
| 9 | 5 | Free check-ins accept 35 responses | tested fact |
| 10 | 4 | What a teacher receives | section label |
| 11 | 4 | How the check-in works | section heading |
| 12 | 9 | Review a student’s explanation, confidence, and optional voice note. | workflow claim |
| 13 | 7 | Use them to plan a follow-up conversation. | usable outcome |
| 14 | 3 | Create one check-in | task heading |
| 15 | 8 | Ask one question about a choice or step. | instruction |
| 16 | 4 | Students explain their reasoning | task heading |
| 17 | 9 | Students can complete the form using only a keyboard. | keyboard claim |
| 18 | 3 | Review each explanation | task heading |
| 19 | 8 | Save tags and notes for your next conversation. | workflow claim |
| 20 | 6 | What this tool does not do | limits heading |
| 21 | 11 | It does not grade, detect AI use, proctor, or verify identity. | tested limit |
| 22 | 2 | Privacy limits | section heading |
| 23 | 6 | Voice deletes on the selected schedule. | retention claim |
| 24 | 5 | Keep private review links secure. | instruction |
| 25 | 5 | Student explanation check-ins for teachers. | footer description |
| 26 | 6 | No automated grading or identity checks. | tested limit |
| 27 | 8 | Original generated classroom art · Param Factory, 2026 | provenance |
| 28 | 7 | Built by Param Factory · version 1.0.0 | release identity |

### README

| # | Words | Text | Result |
| --- | ---: | --- | --- |
| 1 | 3 | Accessible Explanation Check-in | product name |
| 2 | 12 | Collect student reasoning with a low-stakes text or voice check-in for teachers. | summary |
| 3 | 13 | Teachers use it when they want students to explain a choice after classwork. | audience and situation |
| 4 | 2 | Try it | section heading |
| 5 | 7 | Open `/demo` for a populated teacher review. | instruction |
| 6 | 10 | The demo saves edits only in a separate browser key. | isolation claim |
| 7 | 7 | Use **Reset demo** to restore the sample. | instruction |
| 8 | 9 | Use **Start for real** to create a private check-in. | instruction |
| 9 | 3 | Run and test | section heading |
| 10 | 10 | Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain. | operator requirement |
| 11 | 11 | `npm run test:all-claims` reads `.factory/claims.json` and runs every listed command separately. | verification instruction |
| 12 | 5 | It stops at the first failure. | verification behaviour |
| 13 | 9 | The app listens on `PORT` and defaults to `8080`. | runtime claim |
| 14 | 6 | Its frontend build is in `dist/`. | build result |
| 15 | 9 | Local records use `data/` unless configuration supplies another path. | operator detail |
| 16 | 1 | Deploy | section heading |
| 17 | 8 | This is a single-container Rust and Vite application. | technical description |
| 18 | 6 | Build it with the root `Dockerfile`. | instruction |
| 19 | 10 | The image declares port 8080 and the non-root `checkin` user. | runtime claim |
| 20 | 11 | Its claim test executes the release server under an unprivileged UID. | runtime evidence |
| 21 | 6 | Use `scripts/deploy-durable-container.sh` for Container Apps. | instruction |
| 22 | 9 | It mounts a product-specific Azure File share at `/app/data`. | deployment claim |
| 23 | 6 | The deployment uses one SQLite replica. | deployment claim |
| 24 | 7 | The deployment-policy claim test checks both settings. | verification detail |
| 25 | 9 | See privacy, terms, demo notes, and the MIT license. | useful links |

## Demo, privacy, and claims checks

- A fresh sample-data action opened `/demo` with the populated **Watershed
  reasoning** review and three realistic explanations. The persistent banner
  said **“Demo — sample data, nothing is saved”** and exposed **Reset demo**
  and **Start for real**.
- Saving Maya Chen's edited sample note wrote only
  `demo:accessible-explanation-checkin:review`, made no `/api/` request, and
  did not create `recent-checkins`. Reset restored the shipped note. The CSV
  contained a header and all three sample records.
- Demo requests were product-origin-only. The offline reload is covered by the
  executed `@claim:offline-demo` test. No CLI or library sandbox applies.
- All 18 commands in `.factory/claims.json` were run from the fresh clone at
  `/tmp/accessible-explanation-checkin-review4.to9dS0` through
  `npm run test:all-claims`; none failed. This includes privacy-boundary,
  retention, limits, paid-license, checkout, runtime, and deployment claims.
- The brief prohibits automated misconduct inference. Export and print/PDF
  paths exist, so no missing AI, import, export, or sync feature was found.

## Structure and route checks

- `/`, `/demo`, `/create`, `/pricing`, `/privacy`, `/terms`, and
  `/no-such-page` returned 200, 200, 200, 200, 200, 200, and 404. Each had
  `lang=en`, one h1, one main, a route-specific title, description, canonical,
  social metadata, favicon, footer, and Privacy/Terms links.
- Back and forward navigation focused the destination h1. The checked mobile
  routes had no horizontal overflow. The designed 404 has a real 404 status.
- Internal crawlable links returned 200; mailto links were explicit. The
  checkout action identifies itself as external and is covered by the checked
  checkout claim. The original classroom/field-notebook identity is distinct,
  not a generic SaaS template.

## Earlier-finding verification

Every earlier review, polish record, and handoff was read. Each prior finding
was checked in the live deployment and source.

| Finding | Status in this review |
| --- | --- |
| F-1-1 | Fixed: live one-click, populated, resettable, isolated demo. |
| F-1-2 | Fixed: 18 claimed behaviours are inventory-tested from a fresh clone. |
| F-1-3 | Fixed: job, audience, action, and action outcome are first-screen copy. |
| F-1-4 | Fixed: non-root runtime write policy is claim-tested. |
| F-1-5 | Fixed: route and history navigation focus the h1. |
| F-1-6 | Fixed: application and static-404 metadata are complete. |
| F-1-7 | Fixed: unknown routes return the designed HTTP 404. |
| F-1-8 | Fixed: landing headings name tasks and limits. |
| F-1-9 | Fixed: landing sentences meet the word cap. |
| F-1-10 | Fixed: keyboard wording is precise and tested. |
| F-1-11 | Fixed: **Read the three steps** resolves to `#how`. |
| F-1-12 | Fixed: README audience wording is plain. |
| F-1-13 | Fixed: README test instructions are concise and runnable. |
| F-1-14 | Fixed: deployment instruction is concise. |
| F-1-15 | Fixed: deployment/security guidance is concise and test-linked. |
| F-2-1 | Fixed: workflow, retention, limits, billing, privacy, and deployment claims are covered. |
| F-2-2 | Fixed: 404 has the visual system, legal links, metadata, and mobile layout. |
| F-2-3 | Fixed: create and pricing h1s name their tasks. |
| F-2-4 | Fixed: purchase control names its external destination. |
| F-3-1 | Fixed: checkout has a live catalog and redirect claim check. |
| F-3-2 | Fixed: lockfile supports `npm ci` in a fresh clone. |

No prior finding is reopened. F-4-1 is new and remains open.

## Quality-gate evidence

From `/tmp/accessible-explanation-checkin-review4.to9dS0`:

| Command | Result |
| --- | --- |
| `npm ci` | PASS — 86 packages, 0 vulnerabilities |
| `npm test` | PASS — 4 Vitest tests, 11 Rust tests, durable-deployment policy |
| `npm run build` | PASS — `dist/`; 12.47 kB gzip JS and 5.16 kB gzip CSS |
| `npm run test:all-claims` | PASS — all 18 listed claim commands |

## What would make this perfect

Add **Privacy** to every primary header, including the static 404, then add a
route-level navigation regression test and repeat this review. No other change
is indicated by this round.
