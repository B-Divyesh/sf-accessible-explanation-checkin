# Handoff — adversarial review 4

## What was done

Performed a read-only adversarial review of the live deployment and repository
revision `4d64cc563b09798e80701e427aa5c7df7d8d3da3`. No product code changed.
The full report is `.factory/review-4.md`.

## How verified

- Opened the live landing page in fresh 390 × 844 and 1440 × 900 Chromium
  contexts before scrolling.
- Entered demo mode, saved a realistic sample review, inspected browser
  storage and request logs, reset it, and exported the sample CSV.
- Checked live routes, metadata, h1/main landmarks, focus changes, 404 status,
  link destinations, and console output.
- In `/tmp/accessible-explanation-checkin-review4.to9dS0`, ran `npm ci`,
  `npm test`, `npm run build`, and every claims.json command with
  `npm run test:all-claims`.

## Known gap / next step

Review verdict: **FAIL**. `F-4-1` remains: the shared primary header lacks a
Privacy link. Add it to both the SPA shell and static 404 header, add a
route-level test, and rerun the complete review.
