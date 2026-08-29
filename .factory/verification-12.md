# Independent verification 12 — FAIL

- Work order: `accessible-explanation-checkin-verify-12`
- Candidate commit: `5cafb3767a3c71cbfbd0b12e6c46c97495690c94`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC
- Verdict: **FAIL — release blocking deployment defect**

## First-read result

Cold desktop visit to `/` answered the required questions in plain words. It
says that it collects student reasoning, names teachers as the intended user,
and places **Try it with sample data** first. Its adjacent explanation says
“Open a populated teacher review; nothing is saved.” The action opens a
three-response sample review. This mandatory gate passes.

## Release-blocking finding

### BLOCKER — deployed SQLite service can scale to three replicas

The candidate's final required claim command failed from a clean checkout:

```text
npm run verify:live-topology
ERROR: live topology check failed: expected minReplicas=maxReplicas=1;
observed minReplicas=1 maxReplicas=3
```

This is fresh direct Azure control-plane evidence from
`scripts/verify-live-topology.sh`, not a cached builder report. The product
uses SQLite plus a durable snapshot share and explicitly requires one writer.
With `maxReplicas=3`, a traffic increase can run more than one independent
SQLite writer and split or overwrite private check-in state. The backend
service contract and the `durable-deployment-policy` claim require exactly one
active replica. Do not release until the real Container App is restored to
`minReplicas=1`, `maxReplicas=1`, with the Azure File share mounted at
`/app/data`, then rerun the live topology and real revision-persistence
checks.

The first 24 claim commands completed successfully. The 25th claim,
`durable-deployment-policy`, contains a compound command: its fixture commands
passed, but its final live `verify:live-topology` command failed as above.
Under the claims contract, one failed claim test is release blocking.

## Candidate/deployment identity

The live deployment does match the candidate, so this is not a stale-site
false positive:

- `/health` returned `{"build_sha":"5cafb3767a3c71cbfbd0b12e6c46c97495690c94","status":"ok"}`.
- `/`, `/demo`, `/privacy`, and `/terms` returned ETag
  `W/"5cafb3767a3c71cbfbd0b12e6c46c97495690c94"`.
- The live shell loaded `index-0K29JA5U.js`, matching the local production
  build, and the health endpoint was HTTP 200.

## Test evidence

All commands below ran from isolated clean clone `/tmp/aec-qa-8E6q0b` at the
candidate commit, after `npm ci` (86 packages; no reported vulnerabilities).

| Check | Result | Evidence |
| --- | --- | --- |
| Every `.factory/claims.json` command via `npm run test:all-claims` | **FAIL** | 24 claim commands passed; final live topology verification observed `maxReplicas=3` |
| `npm test` | PASS | TypeScript, 5 Vitest tests, 13 Rust tests, deployment fixtures, and mocked durability/topology fixture checks passed |
| `npm run build` | PASS | `dist/` produced; JS 38.93 kB raw / 12.43 kB gzip; CSS 19.30 kB raw / 5.16 kB gzip |
| `npm run test:e2e` | PASS | Desktop: 9 app + 19 claim tests passed, one expected fixture skip. Mobile: 10 app + 10 claim tests passed, expected desktop-only skips. |
| `cargo fmt --all -- --check` | PASS | No formatting changes required |
| `cargo clippy --all-targets --all-features --locked -- -D warnings` | PASS | No warnings |
| `cargo build --release --locked` | PASS | Release binary built |
| Exact container image build | NOT RUN | Docker CLI is absent in this verifier container. The repository runtime-policy claim built and exercised the release server as an unprivileged user successfully. |

`npm test` passes because it runs fixture gates only; it does not invoke the
real Azure query in `npm run verify:live-topology`. The claim runner does, and
therefore gives the controlling result.

## Functional, boundary, privacy, and backend checks

- Live desktop workflow passed: created a check-in with a three-day voice
  schedule, submitted a text explanation/confidence, opened its receipt,
  opened the teacher review, saved a tag/note/follow-up, and exported CSV.
  The CSV contained the submitted student and saved note.
- Direct invalid-create recovery returned HTTP 400 with the clear message
  `Assignment name must be between 1 and 120 characters.`
- Local claim coverage passed the 35-response concurrency boundary, 4 MB voice
  boundary, 120-second recorder stop, expired-voice deletion, private-link
  storage shape, CSV/print receipt flow, offline demo reload, and offline
  student-draft recovery.
- Browser request logs for the live normal flow contained only
  `https://accessible-explanation-checkin.sociobot.in`; no analytics, ads,
  model provider, CDN-font, or third-party script request was made. The demo
  claim runner separately confirmed its sample-data isolation and reset/exit
  disposal behavior.
- A 150-request same-client burst to read-only `GET /api/checkins` yielded 127
  HTTP 405 responses and **23 HTTP 429** responses. A subsequent response was
  HTTP 429 with `Retry-After: 0`. Source configuration is 120 burst requests,
  then one request per second; seven requests refilled during the burst.
- `/health` is healthy and carries the exact build SHA. The SQLite persistence
  unit tests and non-root durable-snapshot claim pass locally, but real
  revision persistence cannot be accepted while the deployment's replica
  topology is unsafe. The repository's `test:live-durability-checker` is a
  mock harness, not a live restart; it must not substitute for the documented
  real revision check.

## Accessibility, responsive, and HTTP policy checks

- Factory `verify-url.sh` passed live `/` (579 ms) and `/demo` (536 ms): title,
  `lang=en`, one H1, main landmark, complete image alt text, named buttons, and
  no console/page errors. Outputs are in
  `.factory/verification-artifacts-12/verify-home/` and
  `.factory/verification-artifacts-12/verify-demo/`.
- Playwright-injected axe-core 4.10.3 found **zero violations** on `/`,
  `/demo`, `/create`, and `/privacy` for WCAG 2.0/2.1/2.2 A/AA tags. The
  standalone axe CLI could not start Chrome in this container, so the
  Playwright browser run was used instead.
- At 390 px, `/demo` had `scrollWidth=clientWidth=390`; the sample banner,
  reset/start-for-real controls, review, and 44 px controls remained usable.
  Reduced-motion context reported `scroll-behavior: auto` and 0.00001s motion
  durations. Existing desktop/mobile keyboard claims passed.
- Live responses include CSP with `frame-ancestors 'none'`, HSTS, nosniff,
  no-referrer policy, and a restrictive Permissions Policy. HTML revalidates;
  hashed JS/CSS/image assets are immutable for one year; private API responses
  are `private, no-store`.

## Required repair and re-verification

1. Deploy through the durable deployment wrapper so the actual custom-domain
   Container App has exactly one replica maximum and the required Azure File
   mount.
2. Run `npm run verify:live-topology` against the candidate and retain its JSON
   output.
3. Run the real `scripts/verify-live-durable-workflow.sh` against production to
   create a record, replace a revision, and prove student/review/receipt reads
   and review fields persist on the replacement.
4. Repeat the entire claims runner from a clean checkout. Do not mark PASS on
   fixture-only deployment tests.
