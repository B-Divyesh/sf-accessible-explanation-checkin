# Accessible Explanation Check-in — verification 10 handoff

## Result: FAIL — do not release

- Candidate: `00eb5aa5561fe46fd0ab5a02adf9799f70f52418`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC
- Full report: `.factory/verification-10.md`

The live deployment is the candidate build but is not durable. It has two running replicas, `maxReplicas: 3`, and no mounted Azure File share at `/app/data`. Private check-ins are visible only on the replica that created them: fresh reads alternate `200`/`404`, and a student can submit successfully then receive a missing receipt. This is a critical release blocker.

## What was verified

- Fresh `npm ci`, local unit/integration suite, desktop and 390 px browser suite, production build, Rust format/Clippy/release build, and non-root runtime policy all passed.
- Cold first-read and one-click sample-demo gates passed.
- Live headers, same-origin request boundary, rate limiting (429 with `Retry-After`), mobile route accessibility, keyboard claims, service-worker demo offline reload, and bundle budgets passed.
- The exact listed `durable-deployment-policy` claim command fails at its live topology gate. Local fixture checks pass but do not validate Azure's current service shape.

## Required next steps

1. Redeploy with exactly one active/running replica and `minReplicas=maxReplicas=1`.
2. Attach the required read-write Azure File share at `/app/data`.
3. Verify `/health` still returns the candidate SHA, then rerun `npm run verify:live-topology` and a fresh create → student submit → receipt → teacher review flow repeatedly and across a revision replacement.
4. Start a new independent verification only after those checks pass.

No product source files were changed during verification. The pre-existing `graphify-out` worktree changes were preserved.
