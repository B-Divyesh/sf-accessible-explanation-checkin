# Adversarial first-read review 8 — FAIL

- Product: Accessible Explanation Check-in
- Reviewed: 2026-09-02 UTC
- Assigned clean-clone commit: `5a5cf3953a592cb294cfa3a2243bcb62ce2451e7`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Live build: `b6ea22ce6875778503e053da80d0b1279bdc02a9` (`/health`)

## Verdict

**FAIL.** The cold first read, populated demo, privacy boundary, navigation,
metadata, and the earlier product repairs verify successfully. The declared
durable-deployment claim does not run successfully from the assigned clean
clone, and a public numeric input-limit promise is absent from the claim
inventory. A PASS requires zero findings.

## Cold first screen

Fresh Chromium contexts at 390 × 844 and 1440 × 900 showed the same result
before scrolling.

- **What it does:** “Collect student reasoning.”
- **For whom:** “For teachers who need a low-stakes check-in, students explain
  one choice by text or voice.”
- **What to click first:** “Try it with sample data.” Its adjacent text says,
  “Open a populated teacher review; nothing is saved.”

This answers the three required questions without inference. The mobile page
had no horizontal overflow, one `h1`, one `main`, no page or console errors,
and only same-origin first-load requests.

## Findings

### F-6-1 — BLOCKING recurrence — Durable-deployment claim fails from the assigned clean clone

**Location/evidence.** The `durable-deployment-policy` entry in
`.factory/claims.json` includes `npm run verify:live-topology`. From a fresh
clone of the assigned repository head, that command exited non-zero:

```text
ERROR: live topology check failed: image
sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:b6ea22ce6875
does not identify build 5a5cf3953a59
```

The live `/health` endpoint independently reports `b6ea22ce…`; the clean
clone is `5a5cf395…`. The manifest runner was run from that clone. It reaches
this final durable-deployment assertion after the preceding claim commands,
then cannot complete successfully because its test requires the live image to
equal the reviewer/verifier commit.

**Why this fails.** This is the same live-image/claim-test condition recorded
as F-6-1 in review 7. A visitor cannot see this distinction, but the claimed
release proof is not reproducible from the current assigned source. The work
order requires every listed claim test to pass; this one fails.

**Concrete fix.** Keep the release identity asserted against the product
candidate SHA rather than `git rev-parse HEAD` after verifier-only commits, or
deploy the assigned candidate before making that command part of the claim.
Add a regression test that checks the verifier commit does not change the
expected product build identity.

### F-8-1 — MEDIUM — The 1,200-character prompt limit is an unlisted quantitative claim

**Location/quote.** `/create`, field note: “Aim for one answerable question.
1,200 characters maximum.”

**Why this fails.** A teacher can rely on this exact numeric limit when writing
their prompt, but no entry in `.factory/claims.json` names or tests it.
`stored-record-shape` tests stored fields and limits generally; it does not
state or assert this public 1,200-character boundary. The claims contract
requires every quantitative public promise to have its own observable test.

**Concrete fix.** Add `prompt-character-limit` to `.factory/claims.json` and
one `@claim:prompt-character-limit` test from a fresh demo context that proves
1,200 characters create a check-in and 1,201 returns the displayed recovery
error. Alternatively remove the number from public copy.

### F-8-2 — MINOR — “judgement” is inconsistent with the product’s “judgment” term

**Location/quote.** `/terms` section heading: “No automated judgement.” The
claim inventory and its corresponding claim use `no-automated-judgment`.

**Why this fails.** The product otherwise uses American spelling in its public
and technical language. The split spelling weakens the promised single,
consistent term for a central product boundary.

**Concrete fix.** Rewrite the heading as “No automated judgment.”

## Copy audit

Counts are whitespace-delimited. Standalone headings and controls are included
because they are heard by screen-reader users and make up the cold first read.
No landing or README item exceeds 22 words. No landing button is a
non-result-naming verb. The two flags above are outside the landing/README
word-length check.

### Landing page

| # | Words | Text | Result |
| --- | ---: | --- | --- |
| 1 | 5 | Student explanation check-ins for teachers | Informational label |
| 2 | 3 | Collect student reasoning | Job-first h1 |
| 3 | 15 | For teachers who need a low-stakes check-in, students explain one choice by text or voice. | Plain audience/outcome |
| 4 | 5 | Try it with sample data | Result-naming action |
| 5 | 8 | Open a populated teacher review; nothing is saved. | Plain outcome |
| 6 | 4 | Read the three steps | Result-naming action |
| 7 | 2 | No accounts | Claim: `no-account-needed` |
| 8 | 5 | Voice deletes on your schedule | Claim: `voice-retention-deletion` |
| 9 | 5 | Free check-ins accept 35 responses | Claim: `free-response-limit` |
| 10 | 4 | What a teacher receives | Informational heading |
| 11 | 4 | How the check-in works | Informational heading |
| 12 | 9 | Review a student’s explanation, confidence, and optional voice note. | Claim: `student-review-workflow` |
| 13 | 7 | Use them to plan a follow-up conversation. | Product instruction |
| 14 | 3 | Create one check-in | Informational step |
| 15 | 8 | Ask one question about a choice or step. | Product instruction |
| 16 | 4 | Students explain their reasoning | Informational step |
| 17 | 9 | Students can complete the form using only a keyboard. | Claim: `student-keyboard-flow` |
| 18 | 3 | Review each explanation | Informational step |
| 19 | 8 | Save tags and notes for your next conversation. | Claim: `student-review-workflow` |
| 20 | 6 | What this tool does not do | Informational heading |
| 21 | 11 | It does not grade, detect AI use, proctor, or verify identity. | Claim: `no-automated-judgment` |
| 22 | 2 | Privacy limits | Informational heading |
| 23 | 6 | Voice deletes on the selected schedule. | Claim: `voice-retention-deletion` |
| 24 | 5 | Keep private review links secure. | Safety instruction |
| 25 | 5 | Student explanation check-ins for teachers. | Product one-liner |
| 26 | 6 | No automated grading or identity checks. | Claim: `no-automated-judgment` |
| 27 | 8 | Original generated classroom art · Param Factory, 2026 | Asset provenance |
| 28 | 7 | Built by Param Factory · version 1.0.0 | Builder/version |

### README

| # | Words | Text | Result |
| --- | ---: | --- | --- |
| 1 | 3 | Accessible Explanation Check-in | Document title |
| 2 | 12 | Collect student reasoning with a low-stakes text or voice check-in for teachers. | Product summary |
| 3 | 13 | Teachers use it when they want students to explain a choice after classwork. | Audience/use case |
| 4 | 2 | Try it | Informational heading |
| 5 | 7 | Open `/demo` for a populated teacher review. | Claim: `demo-isolation` |
| 6 | 10 | The demo saves edits only in a separate browser key. | Claim: `demo-isolation` |
| 7 | 7 | Use Reset demo to restore the sample. | Claim: `demo-reset` |
| 8 | 11 | Start for real discards sample edits before creating a private check-in. | Claim: `demo-exit-disposal` |
| 9 | 3 | Run and test | Informational heading |
| 10 | 10 | Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain. | Setup requirement |
| 11 | 11 | `npm run test:all-claims` reads `.factory/claims.json` and runs every listed command separately. | Accurate runner behavior |
| 12 | 6 | It stops at the first failure. | Accurate runner behavior |
| 13 | 9 | The app listens on `PORT` and defaults to `8080`. | Runtime configuration |
| 14 | 6 | Its frontend build is in `dist/`. | Build location |
| 15 | 9 | Local records use `data/` unless configuration supplies another path. | Runtime configuration |
| 16 | 1 | Deploy | Informational heading |
| 17 | 8 | This is a single-container Rust and Vite application. | Architecture description |
| 18 | 6 | Build it with the root `Dockerfile`. | Deployment instruction |
| 19 | 10 | The image declares port 8080 and the non-root `checkin` user. | Claim: `runtime-container-policy` |
| 20 | 11 | Its claim test executes the release server under an unprivileged UID. | Claim: `runtime-container-policy` |
| 21 | 7 | Run `npm run deploy` for Container Apps. | Deployment instruction |
| 22 | 14 | It mounts the factory-registered, product-specific Azure File share at the work order’s `/data` path. | Claim: `durable-deployment-policy` |
| 23 | 8 | One app copy uses a local SQLite database. | Claim: `durable-deployment-policy` |
| 24 | 10 | Each save copies the database and voice upload to `/data`. | Claim: `durable-deployment-policy` |
| 25 | 7 | The next app version restores those files. | Claim: `durable-deployment-policy` |
| 26 | 6 | The deployment uses one SQLite replica. | Claim: `durable-deployment-policy` |
| 27 | 10 | The deployment gate checks private links, submission, and teacher review. | Claim: `durable-deployment-policy` |
| 28 | 9 | It repeats those checks after replacing the production revision. | Claim: `durable-deployment-policy` |
| 29 | 13 | Run `npm run verify:live-topology` to check the live mount, replica, and build identity. | Reproduction instruction; currently fails as F-6-1 |
| 30 | 9 | See privacy, terms, demo notes, and the MIT license. | Documentation links |

## Demo, privacy, and claims checks

- One landing click opened `/demo`; its first screen was already a teacher
  review for “Watershed reasoning” with three named, realistic explanations.
- The persistent banner reads “Demo — sample data, nothing is saved” and
  exposes both **Reset demo** and **Start for real**.
- Editing a sample note created only
  `demo:accessible-explanation-checkin:review`. Reset removed that key and
  restored the shipped note. Starting for real navigated to `/create`, removed
  every `demo:` key, and removed the demo banner.
- The demo request log contained only
  `https://accessible-explanation-checkin.sociobot.in`; no model, analytics,
  advertising, font, or other external request appeared. There were no
  browser console or page errors.
- `.factory/claims.json` has 26 entries. The manifest runner was invoked from
  the fresh clone; its last durable-deployment command is failing as F-6-1.
  The distinct direct reproduction command and exact error are shown above.

## Earlier findings and structure

I read all prior `review-*.md`, `polish-*.md`, and the handoff. Live and source
checks confirm the earlier first-read, demo, demo-disposal, privacy-boundary,
non-root, focus/announcement, metadata, 404, navigation, checkout, mobile,
voice-limit, early-voice-deletion, whole-check-in-deletion, and copy repairs
remain present. The only recurrence is F-6-1 above.

The header/footer are consistent across `/`, `/demo`, `/create`, `/pricing`,
`/privacy`, `/terms`, and the designed HTTP 404. Every inspected route has one
`h1`, one `main`, a route-specific title, description, canonical, and Open
Graph title. The browser history test returned focus to the new `h1` and the
polite announcement said “Opened …”. The site’s internal navigation links
returned 200; the 404’s own skip link returns its expected 404, and `mailto:`
links were explicitly identified. The original classroom identity is distinct
from a generic SaaS template. The brief explicitly excludes automated
judgment, so no missing AI feature is recorded.

## What would make this perfect

Make the live-build assertion stable across verifier-only commits, add a
claim-backed 1,200-character prompt-limit boundary test, and standardize
“judgment.” Then rerun the complete claims manifest from the assigned clean
clone and repeat this cold live review.
