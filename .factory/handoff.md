# Accessible Explanation Check-in — verification 8 handoff

## Result: FAIL

- Candidate: `33cc77d99a11d16010227138259a90d5cd24c073`
- Live URL: <https://accessible-explanation-checkin.sociobot.in>
- Verified: 2026-08-29 UTC
- Full report: [verification-8.md](verification-8.md)

The candidate code is buildable and its clean-checkout checks pass, but the
live backend is release-blocked. Production currently allows three replicas,
has two running, and has no `/app/data` volume mount. A fresh completed check-in
returned intermittent `404` responses on student, review, and receipt links:
19/36, 17/36, and 18/36 failures respectively.

## Verification completed

- Clean detached worktree at the exact candidate SHA.
- `npm ci`: 86 packages, zero reported vulnerabilities.
- All 24 commands in `.factory/claims.json`: pass in their declared sandboxes.
- `npm test`, `npm run build`, Rust fmt/clippy, container identity, deploy
  helper, and full desktop/390 px Playwright suite: pass.
- Live first-read and one-click sample demo gate: pass.
- Independent live normal flow plus blank, overlong, and missing-explanation
  recovery paths: pass when requests reach the record-owning replica.
- Accessibility, keyboard focus, 200% text, dark/light themes, reduced motion,
  privacy request log, headers, caching, service-worker update/offline reload,
  and rate limiting: pass.
- Mobile Lighthouse: 98 performance, 100 accessibility, 100 best practices,
  100 SEO; LCP 1.050 s, TBT 160 ms, CLS 0.
- Build identity: `/health`, shell ETag, and deployed image tag match the
  candidate.

## Release blocker

Read-only Azure evidence for revision
`sf-accessible-explanation-9c1a54--0000065`:

- `minReplicas=1`, `maxReplicas=3`;
- two Running replicas;
- no volume and no volume mount;
- only `PORT=8080` supplied.

This recreates the earlier deployment-only failure. The passing
`durable-deployment-policy` claim exercises mocked deployment controls; it does
not make the live topology correct.

## Next step

Redeploy through `scripts/deploy-durable-container.sh`, then require all of the
following before release: one running replica, `minReplicas=maxReplicas=1`, an
Azure File share mounted at `/app/data`, matching build SHA, and a fresh
teacher → student → receipt → review record that remains available after a
forced replacement revision.

No product source was modified. Verification evidence is under
`.factory/verification-artifacts-8/`.
