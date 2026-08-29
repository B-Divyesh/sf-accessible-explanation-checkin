# Adversarial first-read review 2 — FAIL

- Product: Accessible Explanation Check-in
- Reviewed: 2026-08-29 UTC
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Deployed build: `6430b28613d0a32700fde782519188a5b57cced3` (`/health`)

## Verdict

**FAIL.** The primary teacher workflow is now clear and immediately tryable.
The live 404 still omits required route metadata and the shared navigation
skeleton. More importantly, the claim inventory leaves public promises about
the product, privacy, and paid plan without observable tests. A PASS requires
zero findings and no untested claim.

## Cold first screen

On fresh Chromium at 390 x 844 and 1440 x 900, before scrolling, I understood:

- **What it does:** collects a student's reasoning after classwork in text or
  voice, then gives a teacher a review view.
- **For whom:** teachers who need a low-stakes check-in.
- **What to click first:** **Try it with sample data**, which says it will open
  a populated teacher review and not save real data.

The first screen answers all three questions. It has one h1, `main`, a visible
sample-data action, three short facts, no horizontal overflow at 390 px, and no
console or page errors. This is not a blocking first-read failure.

## Findings

### F-2-1 — BLOCKING — Public claims remain outside the claims inventory

**Location and evidence.** `.factory/claims.json` contains nine entries. The
following live statements have no matching claim entry and observable sandbox
test:

| Location | Exact quote | Why it is unlisted or insufficiently tested |
| --- | --- | --- |
| Landing, “How the check-in works” | “Review a student’s explanation, confidence, and optional voice note.” | No claim proves the promised student-to-review content. |
| Landing, step 2 | “Students can complete every step with a keyboard or screen reader.” | `keyboard-demo` only tabs through the **teacher** demo navigation and download action; it does not exercise every student step or a screen reader path. |
| Landing, step 3 | “Add tags and notes for your next conversation.” | No claim covers saving review tags or notes. |
| Landing, Privacy limits | “Voice deletes on the selected schedule.” | `voice-retention-control` only checks that the create form offers three option labels. It does not prove scheduled deletion. |
| Plans | “Every student mode, receipt, review tag, CSV export and print-to-PDF receipt stays in the free tier.” | No claim covers this free-tier entitlement. |
| Plans | “Classroom Plus is active: extended retention and up to 500 responses.” | No claim covers the paid limit or activation. |
| Plans | “Sociobot/Dodo is the merchant of record. Refunds are handled there and revoke the license.” | No claim or fixture test covers billing/refund behaviour. |
| Privacy | “We do not sell or use classroom data for advertising or model training.” | This privacy promise has no request-log or other test. |
| Privacy | “Voice deletes automatically on the schedule shown before submission...” | No end-to-end deletion test exists. |
| Terms | “The service does not grade, proctor, verify identity, or detect AI use.” | The landing visibility test does not prove the service behaviour claimed on the legal page. |
| README | “The runtime serves the frontend and API on port 8080 as the non-root `checkin` user.” | The repository has a source-policy test, but this public operational claim is absent from `claims.json`. |
| README | “It mounts a product-specific Azure File share at `/app/data` and uses one SQLite replica.” | This deployment/persistence promise is absent from `claims.json`. |

**Why this blocks acceptance.** These are promises a teacher, school, or
operator could rely on. The claims contract requires every such statement to
have one listed, observable test; a text-presence assertion is not evidence for
service behaviour. This is a partial regression of review-1's F-1-2 closure:
an inventory now exists and its nine checks pass, but it does not inventory the
remaining live promises.

**Concrete fix.** Either remove each promise or add a dedicated
`@claim:<id>` entry that names every page where it appears and tests the
observable result from a clean state. In particular, add browser tests for a
student keyboard-only submission and saved teacher review, a controlled
retention/deletion fixture, free/paid entitlement fixtures, and a request-log
privacy allow-list. For deployment statements, add a non-root image execution
test and a durable-mount/single-replica deployment-policy test to the listed
claim inventory. Do not describe billing or data use as proven until a safe
fixture test can prove it.

### F-2-2 — HIGH — The HTTP 404 is outside the site skeleton and lacks route metadata

**Location and evidence.** A live `GET /no-such-page` returns the intended
HTTP 404 and shows “That page is not available.” Its static response
`frontend/public/404.html` has one h1 and main, but no skip link, product
header, footer, Privacy link, Terms link, meta description, canonical link,
Open Graph metadata, Twitter card, or favicon declaration. The same live
inspection found all of those on `/`, `/demo`, `/create`, `/pricing`,
`/privacy`, and `/terms`.

**Why a visitor is lost.** A visitor who follows an incomplete private link
cannot reach Privacy or Terms from the error route, and a shared link has no
description or social preview. This reopens the unfinished part of review-1
F-1-6: metadata is complete for SPA routes but not for the actual server 404.

**Concrete fix.** Give `404.html` the same static header, skip link, footer,
Privacy and Terms links as the application shell. Add a concise description,
canonical URL, OG/Twitter title/description/image, and the existing SVG and
Apple-touch favicon links. Keep the HTTP status 404 and the “Return home” link.
Add a test that fetches an unknown path and asserts these document elements and
the legal links, not only its status and h1.

### F-2-3 — MEDIUM — Two route headings use slogans instead of naming the task

**Location and quote.** `/create` uses “Create one clear opening”; `/pricing`
uses “Start free. Keep accessibility free.”

**Why a visitor is lost.** “Opening” does not name a check-in, and the pricing
heading does not name plans or prices. Both conflict with the plain-words rule
that a heading name its section rather than set a mood.

**Concrete fix.** Change the create h1 to “Create a student explanation
check-in” and the pricing h1 to “Plans and prices.” Retain the useful nearby
details about the student link, free tier, and accessibility.

### F-2-4 — MEDIUM — The billing link does not identify its external destination

**Location and quote.** `/pricing` has **“Buy Classroom Plus”** with an
`https://api.sociobot.in/...` href. Its accessible name and visible label do
not say that the action leaves this product site.

**Why a visitor is lost.** A teacher can reasonably expect a product button to
stay in the product. The shared site-structure contract requires external
links to say so, especially before an account or payment flow.

**Concrete fix.** Change the accessible and visible label to “Buy Classroom
Plus through Sociobot (opens external site)” or add an adjacent visible
external-site notice. Preserve the concise merchant-of-record explanation.

## Copy audit

Word counts are whitespace-delimited. Headings, action labels, facts, and
footer statements are included because they are read as standalone copy. No
landing or README item exceeds 22 words. The only copy findings are F-2-3's
non-landing headings; no banned marketing adjective, terminology conflict,
or non-result-naming landing button was found.

### Landing page

| # | Words | Copy | Result |
| --- | ---: | --- | --- |
| 1 | 5 | Student explanation check-ins for teachers | clear audience label |
| 2 | 3 | Collect student reasoning | clear h1 |
| 3 | 15 | For teachers who need a low-stakes check-in, students explain one choice by text or voice. | clear |
| 4 | 5 | Try it with sample data | result-naming action |
| 5 | 8 | Open a populated teacher review; nothing is saved. | clear demo outcome |
| 6 | 4 | Read the three steps | result-naming action |
| 7 | 2 | No accounts | clear fact |
| 8 | 5 | Voice deletes on your schedule | clear fact; see F-2-1 |
| 9 | 5 | Free check-ins accept 35 responses | clear fact |
| 10 | 4 | What a teacher receives | contextual section label |
| 11 | 4 | How the check-in works | clear section heading |
| 12 | 9 | Review a student’s explanation, confidence, and optional voice note. | clear; see F-2-1 |
| 13 | 7 | Use them to plan a follow-up conversation. | clear |
| 14 | 3 | Create one check-in | clear step heading |
| 15 | 8 | Ask one question about a choice or step. | clear instruction |
| 16 | 4 | Students explain their reasoning | clear step heading |
| 17 | 11 | Students can complete every step with a keyboard or screen reader. | clear; see F-2-1 |
| 18 | 3 | Review each explanation | clear step heading |
| 19 | 8 | Add tags and notes for your next conversation. | clear; see F-2-1 |
| 20 | 6 | What this tool does not do | clear section heading |
| 21 | 11 | It does not grade, detect AI use, proctor, or verify identity. | clear limit |
| 22 | 2 | Privacy limits | clear section heading |
| 23 | 6 | Voice deletes on the selected schedule. | clear; see F-2-1 |
| 24 | 5 | Keep private review links secure. | clear instruction |
| 25 | 5 | Student explanation check-ins for teachers. | clear footer line |
| 26 | 6 | No automated grading or identity checks. | clear footer limit |
| 27 | 8 | Original generated classroom art · Param Factory, 2026 | useful provenance |

### README

| # | Words | Copy | Result |
| --- | ---: | --- | --- |
| 1 | 3 | Accessible Explanation Check-in | product name |
| 2 | 12 | Collect student reasoning with a low-stakes text or voice check-in for teachers. | clear |
| 3 | 13 | Teachers use it when they want students to explain a choice after classwork. | clear |
| 4 | 2 | Try it | clear section heading |
| 5 | 7 | Open `/demo` for a populated teacher review. | clear |
| 6 | 10 | The demo saves edits only in a separate browser key. | clear |
| 7 | 7 | Use **Reset demo** to restore the sample. | clear |
| 8 | 9 | Use **Start for real** to create a private check-in. | clear |
| 9 | 3 | Run and test | clear section heading |
| 10 | 10 | Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain. | clear operator requirement |
| 11 | 9 | Run every public claim check from a clean checkout: | clear instruction |
| 12 | 9 | The app listens on `PORT` and defaults to 8080. | clear operator detail |
| 13 | 6 | Its frontend build is in `dist/`. | clear operator detail |
| 14 | 9 | Local records use `data/` unless configuration supplies another path. | clear operator detail |
| 15 | 1 | Deploy | clear section heading |
| 16 | 8 | This is a single-container Rust and Vite application. | clear operator detail |
| 17 | 6 | Build it with the root `Dockerfile`. | clear instruction |
| 18 | 15 | The runtime serves the frontend and API on port 8080 as the non-root `checkin` user. | clear; see F-2-1 |
| 19 | 5 | Use `scripts/deploy-durable-container.sh` for Container Apps. | clear instruction |
| 20 | 14 | It mounts a product-specific Azure File share at `/app/data` and uses one SQLite replica. | clear; see F-2-1 |
| 21 | 9 | See Privacy, Terms, demo notes, and the MIT license. | clear links |

## Demo, privacy, and claim checks

- Fresh mobile `/demo` and `/?demo=1` immediately showed the populated
  “Watershed reasoning” teacher review with three realistic explanations.
  The visible sticky banner said “Demo — sample data, nothing is saved” and
  included **Reset demo** and **Start for real**.
- Saving an edited sample review wrote only
  `demo:accessible-explanation-checkin:review`; no normal `recent-checkins`
  key was created. **Reset demo** restored Maya Chen's shipped note.
- Downloading the sample CSV produced one header and the three named sample
  responses. The demo request log made only same-origin HTML, JS, and CSS
  requests, and no `/api/` request occurred while editing, saving, resetting,
  or exporting.
- In a fresh detached worktree at `6430b28`, `npm ci` and
  `npm run test:claims` passed all 18 desktop/mobile claim assertions. This
  runs the nine claim definitions named in `.factory/claims.json`; the output
  includes all `@claim:` IDs. The listed tests pass, but F-2-1 identifies
  claims that were never listed.
- The demo reloaded offline after its first visit in the passing
  `@claim:offline-demo` test. No CLI or library sandbox applies to this web
  product.

## Structure, history, and scope checks

- Live `/`, `/demo`, `/create`, `/pricing`, `/privacy`, and `/terms` each had
  one h1/main, route-specific title, description, canonical, OG/Twitter data,
  shared header/footer, and the product-specific classroom visual system.
  Back navigation moved focus to the new h1 and updated the polite announcer.
  The mobile view had no horizontal overflow or console errors.
- `robots.txt`, `sitemap.xml`, manifest, social image, app icons, all internal
  header/footer links, and the actual 404 target returned successfully (the
  last correctly returned 404). The external checkout target returned 404 to a
  HEAD request; it was not followed with GET because that could create a real
  billing session. Confirm its GET/redirect behaviour during the billing
  fixture test added for F-2-1.
- The original classroom art and restrained field-notebook UI are distinct,
  not a generic SaaS hero. The brief calls for a human, non-automated
  explanation check-in; no missing AI feature, embedded provider key, import,
  or sync requirement was found.
- Earlier F-1-1, F-1-3, F-1-4, F-1-5, F-1-7, F-1-9 through F-1-15 were
  confirmed fixed on the live site and in source. F-1-2 is only partially
  fixed (F-2-1), and F-1-6 is only partially fixed on the actual static 404
  (F-2-2). The reviews, polish record, verification records, and prior handoff
  were all read before this retest.

## Quality-gate evidence

From the fresh detached worktree:

```text
npm test       PASS (4 TypeScript + 7 Rust tests)
npm run build  PASS (dist/; 12.52 kB gzip JS, 5.13 kB gzip CSS)
npm run test:e2e  PASS (31 passed, 1 expected desktop-only skip)
npm run test:claims  PASS (18 passed)
```

## What would make this perfect

Put every public promise into the claim inventory with a genuine observable
test, make the live HTTP 404 a full member of the site, label the external
billing destination, and replace the two route slogans with task-naming
headings. Then rerun this complete cold-read, demo-isolation, claim, history,
metadata, routing, link, mobile, and copy audit against the deployed build.
