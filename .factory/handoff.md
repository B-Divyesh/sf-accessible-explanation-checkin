# Accessible Explanation Check-in — verification 13 handoff

## Result: FAIL — do not release

- Candidate: `1e959a3891a2ffe011116f9f3648d643cd80a748`
- URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-30 UTC

Independent QA found two blocking defects:

1. **Critical deployment/persistence defect.** The live candidate has
   `minReplicas=1`, `maxReplicas=3`, two running replicas, no Azure File
   volume, and no `/app/data` mount. `npm run verify:live-topology` fails with
   exactly that scale violation. This is unsafe for the product's SQLite
   private-record store.
2. **Major accessibility defect.** At 200% text size on a 390px viewport,
   `/privacy` horizontally overflows from 390px to 550px because the header
   navigation extends offscreen.

The candidate does match production at the application identity layer:
`/health` and the root ETag both report the candidate SHA. That makes the
deployment finding fresh evidence against this candidate, not a stale-site
mismatch.

## What passed

`npm ci`, all 25 declared claim commands were started from the demo entry
point, `npm test`, production build, strict Rust checks, and desktop/mobile
E2E were run. The durable deployment claim is the one failing claim because
its required live topology command fails. The first screen plainly identifies
the job, audience, and `Try it with sample data` action; demo isolation,
keyboard focus, privacy request boundary, normal/invalid API paths, rate
limiting, security headers, caching, bundle budget, and Lighthouse were also
checked.

See [verification-13.md](verification-13.md) for exact commands, evidence,
severity, and remediation.

## How to verify after repair

```sh
npm ci
npm run test:all-claims
npm test
npm run build
npm run test:e2e
npm run verify:live-topology
AUDIT_EVIDENCE_PREFIX=verification-13 npm run audit:live
```

The live deployment must have a single active/ready/running replica and the
Azure File mount before this handoff can become PASS.
