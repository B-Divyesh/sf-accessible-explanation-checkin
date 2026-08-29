# Adversarial first-read review 3 — FAIL

- Product: Accessible Explanation Check-in
- Reviewed: 2026-08-29 UTC
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Deployed build: `b22fa22778cdbb54cc6ffa7530e179bec1716327` (`/health` / shell ETag)

## Verdict

**FAIL.** The central explanation-check-in workflow is clear, polished, and
tryable. However, the live Classroom Plus purchase button is a dead link: its
advertised Sociobot checkout endpoint returns HTTP 404. A teacher cannot buy
the paid plan they are invited to purchase. The README also tells a fresh
checkout to run `npm ci`, but no lockfile is committed, so that documented
verification setup fails before any test runs.

## Cold first screen

Fresh Chromium contexts at **390 × 844** and **1440 × 900**, before scrolling,
answer all three first-read questions:

- **What it does:** collects a student's reasoning through a text or voice
  explanation.
- **For whom:** teachers needing a low-stakes check-in.
- **What to click first:** **Try it with sample data**; the adjacent text says
  “Open a populated teacher review; nothing is saved.”

The mobile first screen has one visible h1, the action and outcome, all three
plain facts, no horizontal overflow, and no console or page errors. This is
not a blocking first-read failure.

## Findings

### F-3-1 — BLOCKING — The paid checkout action leads to a live 404

**Location / exact quote.** `/pricing`, **“Buy Classroom Plus through
Sociobot (opens external site)”**. Its href is
`https://api.sociobot.in/api/v1/products/accessible-explanation-checkin/checkout`.

**Evidence.** A direct live GET to that exact href returned **HTTP 404** with:

```json
{"error":"enabled factory product","status":404}
```

The link is therefore dead. This also makes the listed
`external-checkout` claim false in production, despite its local test passing:
the Playwright test intercepts that URL and fulfills it with a synthetic
“Sociobot checkout fixture,” so it proves only the static href and label, not
the deployed checkout.

**Why this fails.** A normal teacher who selects the clearly advertised $39
plan is sent to an error instead of checkout. This prevents the freemium
product's paid path from completing and violates the no-dead-links check.

**Concrete fix.** Configure or correct the live Sociobot product checkout so
the public link returns the intended checkout/redirect rather than 404. Keep
the external-site label. Replace the intercept-only assertion with a safe
production integration/preflight test that confirms the configured checkout
endpoint is non-404 without creating a charge; retain the recorded fixture for
the page transition itself. Run that test against the deployment before
claiming the `$39 one-time purchase` claim.

### F-3-2 — HIGH — The documented clean-clone setup command cannot run

**Location / exact quote.** `README.md`, run-and-test block: `npm ci`.

**Evidence.** In a new clone at the reviewed SHA, `npm ci` exits with
`EUSAGE`: “The \`npm ci\` command can only install with an existing
package-lock.json or npm-shrinkwrap.json.” The repository has neither a
`package-lock.json` nor `npm-shrinkwrap.json`. Installing with `npm install`
made the later checks runnable, but selected the current compatible versions
rather than a committed dependency set.

**Why this fails.** The README's primary setup instruction is broken, and the
documented clean-clone claim-verification path is not reproducible. A future
dependency release can change or break the claimed checks without any source
change in this product.

**Concrete fix.** Commit the generated `package-lock.json` for the declared
dependencies, then verify `git clone … && npm ci && npm test && npm run build
&& npm run test:claims` succeeds. Do not substitute `npm install` in the
README as a workaround for an application repository.

## Copy audit

Counts are whitespace-delimited. Headings, facts, button labels, and footer
copy are included because they are announced or read independently. No item is
over 22 words; no landing or README item uses a banned marketing adjective,
metaphor heading, inconsistent product term, or a non-result-naming button.
The wording itself has no finding.

### Landing page

| # | Words | Text | Audit |
| --- | ---: | --- | --- |
| 1 | 5 | Student explanation check-ins for teachers | clear audience label |
| 2 | 3 | Collect student reasoning | clear job-first h1 |
| 3 | 15 | For teachers who need a low-stakes check-in, students explain one choice by text or voice. | clear audience and result |
| 4 | 5 | Try it with sample data | result-naming action |
| 5 | 8 | Open a populated teacher review; nothing is saved. | clear demo outcome |
| 6 | 4 | Read the three steps | result-naming action |
| 7 | 2 | No accounts | clear fact |
| 8 | 5 | Voice deletes on your schedule | clear fact; covered by retention claims |
| 9 | 5 | Free check-ins accept 35 responses | clear fact; covered by limit claim |
| 10 | 4 | What a teacher receives | clear section label |
| 11 | 4 | How the check-in works | clear section heading |
| 12 | 9 | Review a student’s explanation, confidence, and optional voice note. | clear; covered by workflow claim |
| 13 | 7 | Use them to plan a follow-up conversation. | clear outcome |
| 14 | 3 | Create one check-in | clear step heading |
| 15 | 8 | Ask one question about a choice or step. | usable instruction |
| 16 | 4 | Students explain their reasoning | clear step heading |
| 17 | 9 | Students can complete the form using only a keyboard. | clear; covered by keyboard claim |
| 18 | 3 | Review each explanation | clear step heading |
| 19 | 8 | Save tags and notes for your next conversation. | clear; covered by workflow claim |
| 20 | 6 | What this tool does not do | clear limits heading |
| 21 | 11 | It does not grade, detect AI use, proctor, or verify identity. | clear; covered by no-automated-judgment claim |
| 22 | 2 | Privacy limits | clear section heading |
| 23 | 6 | Voice deletes on the selected schedule. | clear; covered by retention-deletion claim |
| 24 | 5 | Keep private review links secure. | usable instruction |
| 25 | 5 | Student explanation check-ins for teachers. | clear footer line |
| 26 | 6 | No automated grading or identity checks. | clear; covered by no-automated-judgment claim |
| 27 | 8 | Original generated classroom art · Param Factory, 2026 | useful provenance |

### README

| # | Words | Text | Audit |
| --- | ---: | --- | --- |
| 1 | 3 | Accessible Explanation Check-in | product name |
| 2 | 12 | Collect student reasoning with a low-stakes text or voice check-in for teachers. | clear summary |
| 3 | 13 | Teachers use it when they want students to explain a choice after classwork. | clear audience and situation |
| 4 | 2 | Try it | clear section heading |
| 5 | 7 | Open `/demo` for a populated teacher review. | clear instruction |
| 6 | 10 | The demo saves edits only in a separate browser key. | clear; covered by demo-isolation claim |
| 7 | 7 | Use **Reset demo** to restore the sample. | clear instruction |
| 8 | 9 | Use **Start for real** to create a private check-in. | clear instruction |
| 9 | 3 | Run and test | clear section heading |
| 10 | 10 | Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain. | necessary operator requirement |
| 11 | 9 | Run every public claim check from a clean checkout: | clear instruction; setup is broken by F-3-2 |
| 12 | 9 | The app listens on `PORT` and defaults to `8080`. | clear operator detail |
| 13 | 6 | Its frontend build is in `dist/`. | clear operator detail |
| 14 | 9 | Local records use `data/` unless configuration supplies another path. | clear operator detail |
| 15 | 1 | Deploy | clear section heading |
| 16 | 8 | This is a single-container Rust and Vite application. | clear technical description |
| 17 | 6 | Build it with the root `Dockerfile`. | clear instruction |
| 18 | 10 | The image declares port 8080 and the non-root `checkin` user. | covered by runtime-policy claim |
| 19 | 9 | Its claim test executes the release server under an unprivileged UID. | covered by runtime-policy claim |
| 20 | 6 | Use `scripts/deploy-durable-container.sh` for Container Apps. | clear instruction |
| 21 | 14 | It mounts a product-specific Azure File share at `/app/data`. | covered by deployment-policy claim |
| 22 | 6 | The deployment uses one SQLite replica. | covered by deployment-policy claim |
| 23 | 7 | The deployment-policy claim test checks both settings. | clear verification detail |
| 24 | 9 | See privacy, terms, demo notes, and the MIT license. | clear links |

## Demo, claims, privacy, and sandbox checks

- Fresh mobile and desktop use of `/`, `/demo`, and `/?demo=1` showed the
  three realistic watershed explanations immediately after the one-click
  action.
- The persistent banner read **“Demo — sample data, nothing is saved”** and
  included **Reset demo** and **Start for real**. Edits save only under
  `demo:accessible-explanation-checkin:review`; Reset removed the edit and
  restored the seed note. No `/api/` request occurred during the demo edit,
  save, reset, or CSV download.
- The live request log for home and demo contained only the product origin
  (HTML, JS, CSS, and self-hosted art). The product makes no model, analytics,
  or advertising request in that flow. The demo's offline claim passed in its
  Playwright test after service-worker control.
- All 18 inventory entries have an implemented tagged test. In the
  clean-derived clone, `npm run test:claims` passed **22** assertions with
  **6 expected mobile skips**; `npm test`, direct retention and paid-limit
  tests, `npm run test:runtime-policy`, and `npm run test:deployment-policy`
  passed. F-3-1 remains because the checkout test records a fixture instead of
  observing the live external route.
- No additional AI feature is required: the brief explicitly calls for a
  non-automated, non-surveillance explanation check-in. CSV export and a
  print/PDF path are present; sync or import is not implied by the brief.

## Structure, accessibility, history, and link checks

- Home, demo, create, plans, privacy, and terms have route-specific titles,
  descriptions, canonicals, Open Graph/Twitter metadata, one h1, one main,
  visible focus treatment, shared header/footer, Privacy/Terms links, and
  product-specific classroom art. The 404 returns HTTP 404 and includes the
  designed header, footer, legal links, metadata, favicon, and return-home
  action.
- Browser checks passed for route-change focus and back navigation, 390 px
  controls, reduced motion, and serious/critical axe findings. The live
  console had no errors in the audited home and demo sessions.
- All internal navigation, legal, asset, robots, sitemap, manifest, and icon
  links returned their expected status (the intentional `/404` document path
  returned 404). The sole dead destination is F-3-1's checkout link.
- The visual system follows the recorded lit-classroom direction and is
  product-specific rather than a generic SaaS template.
- Earlier F-1-1 through F-1-15 and F-2-2 through F-2-4 were rechecked in live
  behavior and source. Their literal fixes hold: the demo is isolated,
  metadata/404/focus/mobile targets hold, headings are task-naming, and the
  external label remains explicit. F-1-2/F-2-1's claim-inventory work is
  materially present, but F-3-1 exposes a remaining false-positive checkout
  test. No earlier finding is merely marked fixed without an implementation.

## Quality-gate evidence

From a fresh clone of `b22fa22`, `npm ci` failed as described in F-3-2. After
the non-reproducible `npm install` fallback, the following passed:

| Command | Result |
| --- | --- |
| `npm test` | PASS — 4 TypeScript/Vitest + 10 Rust tests and deployment policy |
| `npm run build` | PASS — `dist/`; 12.45 kB gzip JS and 5.13 kB gzip CSS |
| `npm run test:e2e` | PASS — 42 browser tests |
| `npm run test:claims` | PASS — 22 passed, 6 expected mobile skips |
| `npm run test:runtime-policy` | PASS — release server ran non-root and wrote its durable snapshot |
| `npm run test:deployment-policy` | PASS — one Azure File-backed SQLite replica |
| direct retention / Classroom Plus claim tests | PASS — one test each |

## What would make this perfect

Make the deployed checkout endpoint real and observable without a payment,
lock the Node dependency graph so the documented clean-clone command works,
then repeat this exact live link crawl and clean-clone claim run. With those
two issues closed, no further first-read, demo, copy, accessibility, routing,
privacy-boundary, visual-identity, or missed-leverage finding was observed.
