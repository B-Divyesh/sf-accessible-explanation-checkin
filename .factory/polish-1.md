# Polish 1 — review finding closure

Candidate reviewed: `de2386a7a15f0b34fb67c58d751d17be87f1a821`.

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Added `/demo` and `?demo=1`, isolated `demo:` storage, a persistent banner, reset, start-real action, realistic three-response review, and demo documentation. | `@claim:demo-isolation`, `@claim:demo-reset`; `.factory/evidence/polish-demo-desktop.png`; local `http://127.0.0.1:18080/demo` |
| F-1-2 | Added `.factory/claims.json` and nine tagged browser claim tests. Each begins from the demo route. | `npm run test:e2e` (29 passed, 1 expected skip); every command listed in `claims.json` |
| F-1-3 | Rewrote the hero around the teacher’s job, the sample action, outcome, and three facts. | `.factory/evidence/polish-home-mobile.png`; `@claim:demo-isolation` |
| F-1-4 | Restored `USER checkin` in the runtime image and made the container identity test reject root. | `npm run test:container-identity`; Dockerfile runtime inspection |
| F-1-5 | Added route-change heading focus and polite announcement; preserved initial skip-link-first keyboard order. | browser test `navigation moves focus…`; `@claim:keyboard-demo` |
| F-1-6 | Added per-route canonical, description, Open Graph, Twitter metadata, social image, and Apple touch icon. | browser test `navigation moves focus…`; local `/create` metadata inspection |
| F-1-7 | Restricted SPA fallback to known routes and return the styled `404.html` with HTTP 404 elsewhere. | browser test `unknown paths…`; local `/no-such-page` returned 404 |
| F-1-8 | Replaced slogans with task headings, “How the check-in works,” “What this tool does not do,” and “Privacy limits.” | `.factory/copy-audit.md`; mobile screenshot |
| F-1-9 | Split the long landing explanation into two short sentences. | `.factory/copy-audit.md` |
| F-1-10 | Replaced jargon with “Students can complete every step with a keyboard or screen reader.” | `.factory/copy-audit.md`; `@claim:keyboard-demo` |
| F-1-11 | Renamed the secondary action to “Read the three steps.” | `.factory/evidence/polish-home-mobile.png` |
| F-1-12 | Rewrote README audience language in plain words. | `README.md` |
| F-1-13 | Replaced the long README test description with short run instructions. | `README.md` |
| F-1-14 | Split the Container Apps instruction into two short sentences. | `README.md` |
| F-1-15 | Removed the overloaded deployment/security sentence and retained concise operational instructions. | `README.md` |

Earlier verification findings remain covered: free-limit concurrency, durable
single-replica deployment, billing origin, cache/security policies, responsive
targets, PWA reload, and baseline accessibility continue to pass in the full
suite. API rate limiting now applies to APIs rather than static navigation, so
normal page use cannot exhaust the service allowance.
