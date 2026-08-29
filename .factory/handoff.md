# Review 5 handoff — FAIL

- Work order: `accessible-explanation-checkin-review-5`
- Repository revision reviewed: `d28bd7579540f81628e11b384c142ac692cebccb`
- Live build reviewed: `976328637bdfe5cdec53afa4e4303882351ef760`
- Review: `.factory/review-5.md`
- Reviewed: 2026-08-29 UTC

## Outcome

The first screen, isolated sample demo, routing, metadata, accessibility,
privacy request boundary, visual identity, and all 18 listed claim commands
pass. The release still fails because real private links are split across live
backend state: a fresh student link returned 11 × 200 and 13 × 404, while its
review and receipt each returned 12 × 200 and 12 × 404.

Review 2's F-2-1 is also reopened because several live storage, refund,
deletion-request, infrastructure, moderation, and change-policy statements are
not represented in `.factory/claims.json`. The README has one 24-word sentence.
The documented combined E2E command again triggered the known Chromium
headless-shell segfault, although every required claim command passed alone.

No product code was modified.

## Verification run

- Fresh Chromium at 390 × 844 and 1440 × 900: first-read pass.
- `npm run audit:live`: pass for routes, Axe, touch targets, focus/history,
  demo isolation/reset/offline, normal workflow, checkout, links, and headers.
- Independent live connections: **fail**; see
  `.factory/evidence/review-5-live-durability.json`.
- Clean clone `/tmp/tmp.5iFoXZyBGx/repo`:
  - `npm ci`: pass.
  - `npm run test:all-claims`: all 18 commands pass.
  - `npm test`: pass.
  - `npm run build`: pass; `dist/` produced.
  - `cargo fmt --all -- --check`: pass.
  - `cargo clippy --all-targets --locked -- -D warnings`: pass.
  - `npm run test:e2e`: 37 passed, 8 skipped, 1 browser-process crash.
- Factory `verify-url.sh`: live `/` and `/demo` pass.

## Required next steps

1. Repair the actual live storage/replica topology and require 24/24 private
   reads before and after a production revision change.
2. Close reopened F-2-1 by removing or testing every claim listed in review 5.
3. Make the combined E2E command stable and shorten the flagged README
   sentence.
4. Rerun the complete review against the new deployment.
