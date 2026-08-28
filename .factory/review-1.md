# Adversarial first-read review 1 — FAIL

- Product: Accessible Explanation Check-in
- Reviewed: 2026-08-28 UTC
- Live URL: https://accessible-explanation-checkin.sociobot.in
- Deployed build: de2386a7a15f0b34fb67c58d751d17be87f1a821 (/health)

## Verdict

**FAIL.** Blocking gaps remain in the first read, demo sandbox, claim verification, and container runtime. The visual identity is original and basic local tests pass; that does not make the requested job tryable or its public promises auditable.

## Cold first screen

At 390 px and desktop, before scrolling, I inferred: “a teacher may create a classroom prompt and ask students for a text or voice explanation, then review it.” The primary action appears to be “Create a check-in.”

The page does not state that audience or job plainly enough to answer without inference. Its h1 is “Hear the thinking. Skip the detector.” and its eyebrow is “A two-minute reasoning ritual.” Neither names teachers, a student explanation check-in, or the result of the first click. “Create a check-in” also does not say what will appear next. This is a blocking first-read failure.

## Findings

### F-1-1 — BLOCKING — No sample-data demo or isolated sandbox

**Evidence.** The landing page has no “Try it with sample data” action. Its only primary action is “Create a check-in.” A fresh Chromium context showed that /demo returns the in-app 404 (“That page is not available”), and /?demo=1 renders the ordinary landing page. Neither page contains “Demo — sample data, nothing is saved”, “Reset demo”, or “Start for real.” The repository also has no .factory/demo.md, demo storage namespace, sample records, or demo tests.

**Why this fails.** A first-time teacher must enter real, persistent storage to see the application. The reviewer cannot test a student response, teacher review, reset, or offline behavior without creating a real check-in.

**Fix.** Add /demo and a first-screen “Try it with sample data” button. Open a populated teacher-review view with a realistic prompt and several responses, show the persistent banner and both controls, use a separate ephemeral backend tenant/namespace, and document/reset it in .factory/demo.md. Add Playwright tests proving demo mutations never reach a real check-in.

### F-1-2 — BLOCKING — Claims have no inventory or observable claim tests

**Evidence.** .factory/claims.json is absent. A repository search found no @claim: tests. Consequently there were no listed claim commands to run from a clean checkout. npm test passed (4 TypeScript/Vitest assertions, 7 Rust tests) and npm run test:e2e passed (7 passed, 1 desktop-only test skipped), but neither suite is claim-tagged or demo-based.

**Unlisted live claims.** “A two-minute reasoning ritual”; “Invite every student to explain one choice in text or voice.”; “Review what they understood, tag what to revisit, and keep a student-controlled receipt.”; “Keyboard and screen-reader paths are first-class.”; “Nothing is automatically graded.”; “No AI detection”; “No proctoring”; “No biometric identity”; “Voice auto-deletes”; and “No AI scoring, surveillance or biometric identity.”

README adds unlisted product, privacy, export, retention, price, billing, hosting, and security claims, including: “It does not detect AI, proctor students, verify identity, or grade work.”; “The service returns separate unguessable student and teacher-review links.”; “Voice also expires automatically.”; “The student keeps a receipt page and can print/save it as PDF.”; “Free check-ins accept 35 responses and 1–7 day voice retention.”; “There is no analytics SDK, advertising, remote font, or third-party runtime script.”; and “Private links are bearer secrets and must be protected.”

**Why this fails.** The normal first-load request log was same-origin only, but that narrow observation cannot establish the landing/README privacy, offline, retention, export, accessibility, or price promises. Demo mode does not exist to test them.

**Fix.** Add a complete claims.json. Either remove each unprovable sentence or give every claim one @claim:<id> test starting at /demo and asserting the outcome. Include request-log allow-list testing for privacy and offline reload after first visit. Run every listed command in CI.

### F-1-3 — BLOCKING — First screen is metaphor-led and does not name the job

**Location/quote.** Hero eyebrow “A two-minute reasoning ritual”, h1 “Hear the thinking. Skip the detector.”, and primary action “Create a check-in.”

**Why this fails.** “Ritual,” “hear the thinking,” and “detector” do not tell a cold visitor what is collected, who uses it, or what the action does. The two-minute number is also an untested quantitative claim.

**Fix.** Use h1 “Collect student reasoning”; lead “For teachers who need a low-stakes check-in, students explain one choice by text or voice.”; action “Try it with sample data”; and adjacent outcome “Open a populated teacher review; nothing is saved.” Include three tested facts such as “No accounts,” “Voice deletes on your schedule,” and the actual free limit.

### F-1-4 — BLOCKING — Earlier container-root finding remains unfixed

**History check.** No earlier review-*.md or polish-*.md files exist. I read .factory/verification.md, .factory/verification-2.md, and the prior handoff. The critical persistence/quota/billing/cache/target findings from verification 1 have source tests or prior live evidence of repair. The sole verification-2 finding remains in current source: the final Docker stage creates checkin, then ends with USER root.

**Why this fails.** This repeats verification-2’s “High — production container runs as root” finding. A network-facing service that stores student text and optional voice runs as root to work around the Azure Files mount.

**Fix.** Restore USER checkin after arranging a writable non-root durable path (or an init/sidecar ownership strategy). Build and execute the actual image, verify its effective UID and snapshot/upload writes, then repeat durability and browser checks. Add a test rejecting a final USER root.

### F-1-5 — High — Route changes leave focus on body and do not announce

**Evidence.** In live Chromium, activating “Create a check-in” changed the URL to /create, but document.activeElement was BODY, not the new h1. The persistent aria-live element receives no route-change message.

**Fix.** Make each rendered h1 programmatically focusable, focus it after the route renders, and announce the route title. Add a Playwright back/forward and focus regression test.

### F-1-6 — High — Missing canonical and social metadata on every audited route

**Evidence.** Live /, /create, /pricing, /privacy, /terms, and the not-found route each had zero canonical links, zero og:* tags, and zero Twitter-card tags. All reuse the home-page description. The home title is “Accessible Explanation Check-in — Hear the thinking”, which repeats the metaphor rather than the product task.

**Fix.** Set a per-route canonical URL, plain per-route description, Open Graph and Twitter title/description/image, and original 1200×630 product art. Use “Accessible Explanation Check-in — Collect student reasoning” for the home title. Add metadata tests.

### F-1-7 — High — The designed 404 has an HTTP 200 status

**Evidence.** GET /no-such-page returned HTTP 200, then rendered “That page is not available.” Source confirms a catch-all ServeDir fallback to index.html without a status override.

**Fix.** Serve a designed 404 document with HTTP 404 for unknown non-SPA paths, while retaining explicit SPA fallbacks for known routes. Add an HTTP-status test.

### F-1-8 — Medium — Landing copy uses non-informational headings and slogans

**Location/quote.** “A two-minute reasoning ritual”; “Hear the thinking. Skip the detector.”; “A clear path from finished work to a teacher’s next question.”; “Evidence without accusation”; “Built for uncertainty, not suspicion.”; and footer “A reasoning ritual, not a detector.”

**Fix.** Use “Student explanation check-ins for teachers”, “What a teacher receives”, “How the check-in works”, “What this tool does not do”, and “Privacy limits.” Remove the redundant footer slogan.

### F-1-9 — Medium — Landing sentence exceeds the 22-word cap

**Quote.** “A student’s own explanation, their confidence, and an optional voice note give you something concrete to follow up—without pretending software can read intent.” (23 words)

**Fix.** “Review a student’s explanation, confidence, and optional voice note. Use them to plan a follow-up conversation.”

### F-1-10 — Medium — Landing terminology is jargon or imprecise

**Quote.** “Keyboard and screen-reader paths are first-class.”

**Fix.** “Students can complete every step with a keyboard or screen reader.” Add its claims test.

### F-1-11 — Medium — Secondary action is not a result-naming verb

**Quote.** “See how it works.”

**Fix.** Rename it “Read the three steps” and ensure it moves to “How the check-in works.”

### F-1-12 — Medium — README uses unexplained audience jargon

**Quote.** “It is designed for teachers working in AI-pervasive classes who need usable evidence for a humane follow-up conversation.”

**Fix.** “Teachers use it when they want students to explain a choice after completing classwork.”

### F-1-13 — Medium — README sentence exceeds the 22-word cap

**Quote.** “The integration test creates a check-in, submits an explanation, reads and updates teacher review, loads a receipt, exports CSV, deletes voice state, and checks health.” (25 words)

**Fix.** “The integration test covers creation, submission, teacher review, receipt, CSV export, voice deletion, and health.”

### F-1-14 — Medium — README deployment instruction exceeds the 22-word cap

**Quote.** “For the factory Container Apps deployment, use scripts/deploy-durable-container.sh: it creates/uses a product-specific Azure File share, mounts it at /app/data, and pins the SQLite service to one replica.” (27 words)

**Fix.** “Use scripts/deploy-durable-container.sh for Container Apps. It mounts a product-specific Azure File share at /app/data and uses one SQLite replica.”

### F-1-15 — Medium — README deployment/security sentence exceeds the 22-word cap

**Quote.** “Deploy behind TLS; the application sends CSP, HSTS, Permissions Policy, no-sniff, no-referrer and cache-policy headers, applies a burst rate limit, and logs structured JSON.” (24 words)

**Fix.** “Deploy behind TLS. The application sends security and cache headers, limits bursts, and writes structured JSON logs.” Link to a technical header list if operators need names.

## Copy audit

Word counts use whitespace-delimited words. Labels: mood = metaphor/slogan/non-informational heading; claim = needs a claims entry; long = more than 22 words; jargon = unexplained term.

### Landing page

| # | Words | Text | Audit |
| --- | ---: | --- | --- |
| 1 | 4 | A two-minute reasoning ritual | mood; claim |
| 2 | 3 | Hear the thinking | mood |
| 3 | 3 | Skip the detector | mood |
| 4 | 11 | Invite every student to explain one choice in text or voice. | claim |
| 5 | 13 | Review what they understood, tag what to revisit, and keep a student-controlled receipt. | claim |
| 6 | 3 | Create a check-in | primary action lacks stated result |
| 7 | 4 | See how it works | non-result button |
| 8 | 11 | A clear path from finished work to a teacher’s next question. | mood |
| 9 | 4 | One prompt, three signals | imprecise heading |
| 10 | 3 | Evidence without accusation | mood |
| 11 | 23 | A student’s own explanation, their confidence, and an optional voice note give you something concrete to follow up—without pretending software can read intent. | long; claim |
| 12 | 4 | Ask one useful question | usable heading |
| 13 | 9 | “What choice mattered most?” works better than another quiz. | claim |
| 14 | 5 | Let students choose their mode | usable heading |
| 15 | 4 | Text, voice, or both. | usable |
| 16 | 6 | Keyboard and screen-reader paths are first-class. | jargon; claim |
| 17 | 4 | Mark the next conversation | imprecise heading |
| 18 | 7 | Use plain review tags and private notes. | claim |
| 19 | 4 | Nothing is automatically graded. | claim |
| 20 | 5 | Built for uncertainty, not suspicion. | mood |
| 21 | 3 | No AI detection | claim |
| 22 | 2 | No proctoring | claim |
| 23 | 3 | No biometric identity | claim |
| 24 | 2 | Voice auto-deletes | claim |
| 25 | 6 | A reasoning ritual, not a detector. | mood |
| 26 | 7 | No AI scoring, surveillance or biometric identity. | claim |
| 27 | 8 | Original generated classroom art · Param Factory, 2026 | provenance; usable |

### README

| # | Words | Text | Audit |
| --- | ---: | --- | --- |
| 1 | 18 | A keyboard- and screen-reader-first classroom utility for collecting a short student explanation, confidence rating, and optional voice note. | claim |
| 2 | 15 | Teachers get plain review tags and private notes rather than an AI-authorship or misconduct score. | claim |
| 3 | 6 | Students receive a private, printable receipt. | claim |
| 4 | 18 | It is designed for teachers working in AI-pervasive classes who need usable evidence for a humane follow-up conversation. | jargon |
| 5 | 12 | It does not detect AI, proctor students, verify identity, or grade work. | claim |
| 6 | 11 | A teacher creates one prompt and chooses a voice deletion schedule. | claim |
| 7 | 9 | The service returns separate unguessable student and teacher-review links. | claim |
| 8 | 12 | Each student responds in text, optional voice, or both and selects confidence. | claim |
| 9 | 15 | The teacher reviews, tags, adds a private note, exports CSV, and can delete voice immediately. | claim |
| 10 | 4 | Voice also expires automatically. | claim |
| 11 | 12 | The student keeps a receipt page and can print/save it as PDF. | claim |
| 12 | 10 | Free check-ins accept 35 responses and 1–7 day voice retention. | claim |
| 13 | 18 | Classroom Plus is a $39 one-time license unlock for up to 500 responses and 1–365 day voice retention. | claim |
| 14 | 13 | Checkout and verification use the Sociobot billing API; no payment provider is embedded. | claim/jargon |
| 15 | 6 | Accessibility and exports are never gated. | claim |
| 16 | 10 | Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain. | usable |
| 17 | 14 | Vite runs on http://localhost:5173 and proxies API requests to the Rust server on http://localhost:8080. | usable |
| 18 | 6 | Local records are written under data/. | usable |
| 19 | 12 | npm test runs the TypeScript unit tests and Rust unit/integration API flow. | claim about test scope |
| 20 | 25 | The integration test creates a check-in, submits an explanation, reads and updates teacher review, loads a receipt, exports CSV, deletes voice state, and checks health. | long |
| 21 | 9 | For an HTTP load smoke against a running server: | usable label |
| 22 | 9 | The product defaults to the production Sociobot billing service. | claim |
| 23 | 10 | A staging build may explicitly supply https://pilot-api.sociobot.in for both variables. | usable |
| 24 | 12 | The product slug is used in URLs; no product ID is hardcoded. | implementation detail |
| 25 | 12 | There is no analytics SDK, advertising, remote font, or third-party runtime script. | claim |
| 26 | 9 | Private links are bearer secrets and must be protected. | jargon/claim |
| 27 | 10 | Back up the SQLite database and the voice directory together. | usable |
| 28 | 5 | Mount /app/data on durable storage. | usable |
| 29 | 27 | For the factory Container Apps deployment, use scripts/deploy-durable-container.sh: it creates/uses a product-specific Azure File share, mounts it at /app/data, and pins the SQLite service to one replica. | long |
| 30 | 24 | Deploy behind TLS; the application sends CSP, HSTS, Permissions Policy, no-sniff, no-referrer and cache-policy headers, applies a burst rate limit, and logs structured JSON. | long/jargon |
| 31 | 6 | See /privacy, /terms, .factory/design.md, and .factory/handoff.md. | usable |
| 32 | 4 | MIT — see LICENSE. | usable |

Terminology observed: use **check-in** for the teacher-created activity, **explanation** for the student response, **review** for the teacher view, and **receipt** for the student record. Remove **ritual**, **signals**, and **detector** from explanatory copy because they name neither a product object nor a task.

## Checks completed

- Fresh Chromium contexts at 1440×900 and 390×844: no console/page errors; no horizontal overflow; one h1 and one main on the landing page. The ordinary initial request log contained only product-origin HTML, JS, CSS, and hero art.
- Live route checks: /, /create, /pricing, /privacy, /terms, /robots.txt, /sitemap.xml, and manifest returned 200. /demo also returned 200 but rendered the application’s not-found state. /no-such-page returned 200 and rendered that same state.
- Clean dependency install: npm ci passed. npm test, npm run build, and npm run test:e2e passed as described in F-1-2. Build output: 32.28 kB JS (10.91 kB gzip) and 17.82 kB CSS (4.87 kB gzip).
- The hero is product-specific, not a generic SaaS card/gradient template. No missing AI feature is recorded: the brief explicitly needs a non-automated, low-stakes explanation workflow, and no decorative AI or embedded provider key was found.

## What would make this perfect

Ship the job-first, teacher-specific first screen; a truly isolated populated demo; claim inventory plus demo-based proof; non-root runtime; complete route focus/announcement and metadata/404 behavior; then rerun this entire review against the deployed build. At that point the original classroom art and the clear no-surveillance scope would have a trustworthy, immediately tryable product around them.

