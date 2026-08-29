# Adversarial review 6 handoff — FAIL

- Work order: `accessible-explanation-checkin-review-6`
- Repository revision reviewed: `9595291790ab0a928072be63029962e5e0690946`
- Live build: `483d53c459b569633ce8682503b76447aee4fe19`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Completed: 2026-08-29 UTC

## Outcome

Review 6 is recorded in `.factory/review-6.md`. No product code was changed.

The verdict is FAIL. The live deployment has regressed to `minReplicas: 1`,
`maxReplicas: 3` with no volume or `/app/data` mount. A fresh private student
link returned 12 successful reads and 12 false 404s; its review link returned
13 successful reads and 11 false 404s. A second 12-check-in probe reproduced
student-link and submission 404s on every fresh request context. This reopens
the earlier F-5-1 durability failure.

The review also records unlisted claims for the 2-minute/4-MB voice limits and
teacher-initiated early voice deletion, demo edits surviving the transition to
the real workflow, and one jargon-heavy README sentence.

## Verification completed

- Fresh clone: `/tmp/aec-review6.BvQYAn/repo` at `9595291`.
- `npm ci`: passed; 86 packages, zero vulnerabilities.
- `npm run test:all-claims`: passed all 21 listed commands independently.
- `npm test`: passed; 5 Vitest tests, 12 Rust tests, and deployment fixtures.
- `npm run build`: passed and produced `dist/`; JS 12.31 kB gzip.
- `npm run test:e2e`: passed; 43 passed and 9 intentional device skips.
- Rust formatting and clippy with warnings denied: passed.
- Live route, metadata, link, focus, demo, offline, request-origin, checkout,
  security-header, mobile, dark-theme, and Axe audit: passed.
- Factory `verify-url.sh`: passed with no console errors.
- Azure topology inspection and fresh cross-connection private-link probes:
  failed as described above.

Evidence is in `.factory/evidence/review-6-*`.

## Required next steps

1. Restore one replica and the Azure File `/app/data` mount through the durable
   deployment wrapper; prevent later generic deploys from removing them.
2. Gate release on 24/24 student, review, and receipt reads before and after an
   actual new revision.
3. Add tagged claims for recording limits and early teacher voice deletion.
4. Clear demo state when leaving for the real workflow.
5. Replace the README deployment jargon and repeat the full review.
