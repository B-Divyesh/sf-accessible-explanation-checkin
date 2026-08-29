# Polish 2 — cumulative finding closure

Candidate reviewed: `6430b28613d0a32700fde782519188a5b57cced3`.

| Finding | Change made | Evidence |
| --- | --- | --- |
| F-1-1 | Kept `/demo` and `/?demo=1` as one-click, populated, isolated sample routes with banner, reset, and start-real controls. | `@claim:demo-isolation`, `@claim:demo-reset`; `.factory/evidence/polish-2-local-demo/screenshot-mobile.png`; live `/demo` and `/?demo=1`. |
| F-1-2 | Expanded `.factory/claims.json` from nine shallow claims to 18 observable browser, backend, runtime, and deployment claims. | Every command in `.factory/claims.json` passed in clean clone `/tmp/tmp.mlGoZLbNKF/repo`. |
| F-1-3 | Retained the job-first “Collect student reasoning” first screen, teacher sentence, sample action, outcome, and three tested facts. | `@claim:demo-isolation`; `.factory/evidence/polish-2-local-home/screenshot-mobile.png`; live `/`. |
| F-1-4 | Retained `USER checkin` and added execution proof that the release server writes its durable snapshot under an unprivileged UID. | `npm run test:runtime-policy`; live `/health`. |
| F-1-5 | Retained h1 focus and polite route announcements for link, back, and forward navigation. | Browser test `navigation moves focus to the new heading and updates route metadata`; live `/create`. |
| F-1-6 | Retained route metadata and completed metadata for the real static 404. | Browser tests `navigation moves focus...` and `unknown paths...`; live `/no-such-page`. |
| F-1-7 | Retained an HTTP 404 response for unknown paths. | Browser test `unknown paths return the designed 404...`; live `/no-such-page` returned 404. |
| F-1-8 | Retained task-naming landing headings and removed metaphor-led slogans. | `.factory/copy-audit.md`; `.factory/evidence/polish-2-local-home/screenshot-mobile.png`; live `/`. |
| F-1-9 | Retained the split, short explanation sentences. | `.factory/copy-audit.md`; live `/`. |
| F-1-10 | Replaced the overbroad screen-reader sentence with the precise, tested keyboard claim. | `@claim:student-keyboard-flow`; live `/`. |
| F-1-11 | Retained “Read the three steps” and its `#how` destination. | Browser landing check; live `/#how`. |
| F-1-12 | Retained plain README audience wording. | `README.md`; copy audit. |
| F-1-13 | Retained concise test instructions and listed the full claim suite. | `README.md`; `npm test`. |
| F-1-14 | Retained short deployment instructions. | `README.md`; `@claim:durable-deployment-policy`. |
| F-1-15 | Kept deployment and security instructions short and test-linked. | `README.md`; `npm test`; security-header live check. |
| F-2-1 | Added real student keyboard submission, student-to-review persistence, tag/note reload, receipt/print/CSV, automatic voice cleanup, free quota, paid limits, revoked-license, checkout, privacy request, non-root, and durable-deployment tests. Also removed the unprovable data-sale statement. | `@claim:student-keyboard-flow`, `@claim:student-review-workflow`, `routes::tests::claim_voice_retention_deletion`, `routes::tests::claim_classroom_plus_limits`, `@claim:billing-license-fixture`, `@claim:privacy-request-boundary`, runtime/deployment policy claims. |
| F-2-2 | Rebuilt `404.html` with the site header, skip link, footer, legal links, description, canonical, OG/Twitter data, favicons, mobile layout, and the original doorway visual language. | Browser test `unknown paths...`; `.factory/evidence/polish-2-local-404-mobile.png`; live `/no-such-page`. |
| F-2-3 | Changed the h1s to “Create a student explanation check-in” and “Plans and prices.” | Browser route inspection; live `/create` and `/pricing`. |
| F-2-4 | Changed the label to “Buy Classroom Plus through Sociobot (opens external site).” | `@claim:external-checkout`; live `/pricing`. |

## Additional verification

- `npm test`: 4 Vitest and 10 Rust tests passed, including forwarded-IP rate limiting with `Retry-After`.
- `npm run test:e2e`: 35 passed, 7 expected single-fixture/mobile skips.
- `npm run test:claims`: 22 passed, 6 expected single-fixture/mobile skips.
- `cargo clippy --all-targets --locked -- -D warnings`: passed.
- Production bundle: 12.45 kB gzip JavaScript and 5.13 kB gzip CSS.
- Local Lighthouse mobile: 100 performance, 100 accessibility, 100 best practices, 100 SEO; LCP 1.3 s, TBT 70 ms, CLS 0.
- Local `verify-url.sh` reported one h1, one main, `lang=en`, complete image alt text, and zero console errors on home and demo.
