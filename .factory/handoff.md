# Repair 4 handoff

- Work order: `accessible-explanation-checkin-repair-4`
- Repaired verifier report: commit `2126f93bc66eb51d7cc6ec648f141e2b3cca0638`
- Failed candidate: `771b1f4f9f6dc80b89a949cf1f63473f7690ea55`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Date: 2026-08-29 UTC

## Release blocker repaired

The candidate was reproduced with its Azure Container App forced back to the
verifier's effective three-replica state. The app had no volume or mount. A new
check-in returned 201, but 18 student-link reads split 8 × 200 and 10 × 404;
18 review-link reads split 5 × 200 and 13 × 404. A valid student submission
returned 404. This reproduced the verifier's central workflow failure.

`scripts/deploy-durable-container.sh` remains the only supported deployment
entry point. It applies the product-specific Azure File share at `/app/data`,
sets both replica limits to one, waits for the latest ready revision and one
running replica, and deactivates stale revisions.

The wrapper now also runs `scripts/verify-live-durable-workflow.sh`. Deployment
cannot succeed unless the live service completes all of these checks:

- control plane: one minimum replica, one maximum replica, one running replica,
  Azure Files volume, and `/app/data` mount;
- create one real check-in, then receive 12/12 successful student-link reads
  and 12/12 successful review-link reads;
- submit a student explanation, read it in the teacher review, and save a tag,
  note, and follow-up state;
- restart the actual Container Apps revision;
- receive another 12/12 successful reads for each private link and recover the
  student receipt plus the saved teacher review after restart;
- match `/health.build_sha` to the deployed repository commit.

`scripts/test-live-durable-workflow.sh` executes that exact gate against
recorded Azure and HTTP fixtures. It also injects the reported 404 failure and
proves that the gate rejects it. `scripts/test-durable-deploy.sh` proves the
deployment wrapper invokes the live gate and still fails if Azure does not
apply the durable topology.

## Verification evidence

- Clean `npm ci`: 86 packages installed; zero reported vulnerabilities.
- `npm test`: 5 Vitest tests, 11 Rust tests, the topology regression, and the
  new live-workflow/restart regression passed.
- `npm run test:e2e`: 38 passed and 8 intended mobile duplicate skips across
  desktop Chromium and 390 × 844 mobile Chromium. It covers semantics, console
  errors, keyboard navigation, the complete classroom workflow, Axe, privacy,
  and offline reload.
- `npm run test:all-claims`: all 18 declared claim commands passed independently.
- `npm run build`: `dist/` produced; initial JavaScript is 38,782 bytes raw /
  12,480 gzip and CSS is 19,296 bytes raw / 5,160 gzip.
- `cargo fmt --all -- --check`, `cargo clippy --all-targets --locked -- -D
  warnings`, and `cargo build --release --locked`: passed.
- `npm run test:deploy-helper`, `npm run test:container-identity`, and
  `npm run test:runtime-policy`: passed. The release server ran under an
  unprivileged UID and wrote a durable snapshot.
- Factory `verify-url.sh` on local `/` and `/demo`: HTTP 200, no console
  errors, one H1, `lang=en`, a main landmark, no missing image alternatives,
  and no unlabeled buttons at desktop and 390 px. Evidence is in
  `.factory/evidence/repair-4-local-home/` and `repair-4-local-demo/`.
- The final deployment is performed only after this handoff is committed. The
  wrapper's mandatory live output is the authoritative create/read/submit/
  review/restart evidence for that exact commit; `/health` must match `HEAD`.

## Run and deploy

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:all-claims
cargo fmt --all -- --check
cargo clippy --all-targets --locked -- -D warnings
cargo build --release --locked
scripts/deploy-durable-container.sh accessible-explanation-checkin /work/repo Dockerfile 8080
```

Do not use the generic container helper directly. Its default stateless 1–3
replica template is incompatible with this SQLite service.

## Known gaps

No product release blockers are known. SQLite is intentionally single-writer;
all future deployments must keep the Azure Files mount and one-replica policy.
