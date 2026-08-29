# Repair 5 handoff — PASS

- Work order: `accessible-explanation-checkin-repair-5`
- Verifier report: `31178d896709a4851c53776e757a7dbe59ee0a9f`
- Repaired candidate: `6c0209c9f783f69e9c6a90fb34aa1ef9765415cf`
- Repair runtime commit: `c949913b58d06915a1cf243576159622cdeb0eb0`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC

## Release decision

**PASS.** The sole Critical finding is repaired and proved in production. The
live app now has one active, healthy revision with effective scale `1/1`. Its
existing Azure File share is mounted at `/app/data`. A complete private record
survived replacement by a distinct production revision and every repeated
cross-connection read succeeded.

## Failure reproduced before repair

The unsafe deployment was first raised from one to two running replicas without
adding a volume. Revision `0000047` still had max replicas 3, `volumes: null`,
and `volumeMounts: null`. One fresh `POST /api/checkins` returned 201, then:

- student link: 13 × 200 and 7 × 404 across 20 new connections;
- review link: 12 × 200 and 8 × 404 across 20 new connections;
- the 404 body exactly matched the verifier: “That private link is not valid.
  Check that you copied the whole link.”

Evidence: `evidence/repair-5-reproduction.json`.

## Root cause and repair

The generic container deploy had replaced the repository's required SQLite
topology with a stateless template that allowed three replicas. Separate
container filesystems therefore held different private records.

The durable deployment path was applied to production and its release gate was
strengthened. It now verifies the exact environment storage binding and share,
the `/app/data` mount, effective min/max replicas of 1, one active revision, and
one running replica. It creates a check-in and student submission, saves the
teacher's tag, note, and follow-up state, then creates a distinct production
revision. It requires 12/12 student and 12/12 review reads both before and after
that revision and rechecks the receipt and saved review.

The regression fixture performs that full revision transition. It also injects
the reported private-link 404 and proves the deploy gate rejects it. Run it with:

```sh
npm run test:deployment-policy
npm run test:live-durability-checker
```

## Production durability evidence

Deployment moved from revision `0000049` to `0000050`, both serving build
`c949913b58d06915a1cf243576159622cdeb0eb0`:

- min replicas 1; max replicas 1;
- one active revision and one running replica;
- volume `checkin-data` → storage `aec-accessible-explanati-9c1a54`;
- existing read-write share `sf-accessible-explanation-checkin-data`;
- mount path `/app/data`;
- before the new revision: 12/12 student reads, 12/12 review reads, submission
  201, teacher review saved;
- after the new revision: 12/12 student reads, 12/12 review reads, receipt 200,
  and the full submission/review content persisted.

Evidence: `evidence/repair-5-live-durability.json` and
`evidence/repair-5-live-topology.json`.

## Clean local verification

- `npm ci`: PASS — 86 packages, 0 reported vulnerabilities.
- `npm test`: PASS — TypeScript, 5 Vitest tests, 11 Rust tests, and both
  deployment regressions.
- `node scripts/test-all-claims.mjs`: PASS — all 18 claim commands.
- `npm run build`: PASS — `dist/` produced; JS 38,782 bytes raw / 12,480 gzip;
  CSS 19,296 raw / 5,159 gzip; largest hero 56,604 bytes.
- `cargo fmt --all -- --check`: PASS.
- `cargo clippy --all-targets --locked -- -D warnings`: PASS.
- `cargo build --release --locked`: PASS.
- container-name, build-identity, and non-root runtime checks: PASS.
- desktop browser: 22 passed, 1 intended skip.
- 390px mobile browser: app 9 passed; claims 7 passed, 7 intended skips.
- Factory URL checks on local `/` and `/demo`: 200, correct title/lang/H1/main,
  no missing alt text, no unnamed buttons, and zero console errors.

Two combined Playwright attempts each completed 37 assertions before Chromium
headless-shell itself segfaulted while opening a different mobile case. Both
affected cases passed alone, and every desktop/mobile case passed when split
into smaller runs. This reproduces the verifier's documented runner instability
and is not a page assertion failure.

## Live product verification

`.factory/live-audit.mjs` passed on the repaired deployment:

- seven routes plus the real 404 at 390px in light and dark modes;
- zero serious/critical Axe findings, undersized targets, horizontal overflow,
  console errors, or page errors;
- route focus and announcements, keyboard flows, 200% text, and reduced motion;
- isolated/resettable three-record demo with no API calls and offline reload;
- create → student response → receipt → saved/reloaded teacher review;
- only the product origin during the classroom flow;
- all 14 links valid, production $39 checkout redirect valid;
- CSP, HSTS, Permissions Policy, nosniff, no-referrer, private no-store policy,
  and request IDs present.

Factory `verify-url.sh` also passed live `/` and `/demo` at desktop and 390px.
The mobile Lighthouse result was Performance 100, Accessibility 100, Best
Practices 100, SEO 100; FCP 1.0 s, LCP 1.1 s, TBT 60 ms, CLS 0, 38 KiB total.

Rate limiting with one forwarded client produced 124 expected 404 responses and
56 × 429 across 180 concurrent requests; all 56 rate-limit responses had
`Retry-After`. A different client remained unblocked. Local `dist/` and live
HTML, JS, CSS, manifest, and service worker matched byte-for-byte. `/health`
and the root ETag reported the repair commit.

Evidence: `evidence/repair-5-live-check.json`,
`evidence/repair-5-lighthouse-mobile.json`, `evidence/repair-5-rate-limit.json`,
`evidence/repair-5-identity.json`, and the `repair-5-live-{home,demo}` folders.

## Known gaps and next steps

No release-blocking product gap remains. Future production releases must use
`scripts/deploy-durable-container.sh`; the generic stateless helper alone is
not a valid deployment path for this SQLite service. Keep the exact share,
single-replica, cross-connection, and new-revision checks as release gates.

## Independent verifier addendum — 2026-08-29 — FAIL

**Tested candidate:** `976328637bdfe5cdec53afa4e4303882351ef760`
**Tested URL:** https://accessible-explanation-checkin.sociobot.in

**Do not release.** Fresh independent QA found that the live service identifies
as this candidate, but it still serves two isolated backend replicas. A fresh
private student link returned 12/24 successful reads and 12/24 404s. After a
successful student submission, teacher-review reads had the same 12/12 split
and the receipt returned 404. This is a critical persistence failure.

The rate boundary confirms the topology defect: 160 reads from one forwarded
client all returned 404, while 300 returned 240 × 404 then 60 × 429 with
`Retry-After: 0`. The observed live allowance is 240 (two 120-request bursts),
not the intended one-writer allowance.

All local claim commands (18/18), `npm test`, production build, full E2E,
format/clippy, runtime policy, deployment fixtures, and live UI/accessibility/
privacy audit passed. The successful normal live flow stayed on one replica and
does not mitigate this defect. Full evidence and re-verification detail are in
`.factory/verification-6.md` and
`evidence/verification-6-server-boundaries.json`.
