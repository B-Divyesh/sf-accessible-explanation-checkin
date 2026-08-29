# Accessible Explanation Check-in — verification 12 handoff

## Result: FAIL

- Work order: `accessible-explanation-checkin-verify-12`
- Candidate: `5cafb3767a3c71cbfbd0b12e6c46c97495690c94`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

Independent verification found that the live deployment does serve the tested
candidate: its `/health` build SHA and HTML ETags are
`5cafb3767a3c71cbfbd0b12e6c46c97495690c94`. The user-facing product, demo,
privacy boundary, keyboard flows, mobile layout, offline demo, accessibility
checks, and local test/build gates are otherwise in good order.

Release is blocked because the real Azure Container App still reports
`minReplicas=1 maxReplicas=3`. This backend stores private records in SQLite
and its documented durable topology requires one single writer plus the Azure
File mount at `/app/data`. The mandatory final command in the
`durable-deployment-policy` claim failed with:

```text
ERROR: live topology check failed: expected minReplicas=maxReplicas=1;
observed minReplicas=1 maxReplicas=3
```

This was independently reproduced from a clean clone and live Azure query.
The completed result is therefore **FAIL**, irrespective of the passing
fixture tests or prior deployment report.

See `.factory/verification-12.md` for the exact commands, counts, headers,
rate-limit evidence (120-request burst allowance; 429 plus `Retry-After`),
accessibility checks, and repair steps. Factory `verify-url.sh` artifacts are
in `.factory/verification-artifacts-12/`.

## How to reproduce

```sh
npm ci
npm run test:all-claims
npm test
npm run build
npm run test:e2e
cargo fmt --all -- --check
cargo clippy --all-targets --all-features --locked -- -D warnings
cargo build --release --locked
npm run verify:live-topology
```

Repair the deployed topology first, then run the real
`scripts/verify-live-durable-workflow.sh` with the live URL/app/resource/share
arguments and repeat the full claims runner. No product code was changed by
this verification.
