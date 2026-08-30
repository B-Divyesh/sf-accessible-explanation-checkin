# Accessible Explanation Check-in — repair 12 handoff

## Result: repaired and deployed

This repair addresses the two release blockers in independent verification 14
for candidate `0f0421dd4ea5b076ff61f8cc90abba47b27d2841`.

1. **Durable SQLite topology.** `npm run deploy` remains the required release
   command. It builds through the factory helper, attaches this product's
   Azure File share at `/app/data`, pins `minReplicas=maxReplicas=1`, retires
   stale revisions, runs the private-record replacement-revision workflow,
   then checks the effective production topology and current build identity.
   The deployment regression now reproduces verification 14's exact failure:
   if the revision created by the durability workflow regresses to a 1–3
   replica template, the real topology checker fails with the observed
   `expected minReplicas=maxReplicas=1` error.
2. **Classroom Plus checkout.** The production Sociobot catalog is available
   again. The exact declared checkout claim confirms the public catalog's
   `accessible-explanation-checkin` item at 3900 USD cents and requires the
   no-payment checkout request to return a Dodo `303` session redirect. No
   payment information is submitted by the test.

The prior verifier report remains at
[verification-14.md](verification-14.md) for the original evidence.

## Regression coverage

- `scripts/test-durable-deploy.sh` uses the actual
  `scripts/verify-live-topology.sh` against a mocked Azure control plane. It
  first accepts the fully mounted, single-replica revision, then makes the
  post-workflow revision report `maxReplicas: 3` and requires deployment to
  fail. This protects the final check's ordering as well as its predicate.
- `frontend/tests/claims.spec.ts` retains the exact live
  `@claim:external-checkout` test. It checks catalog data, price, product
  slug, checkout endpoint, and a `303` redirect to a Dodo checkout session,
  then verifies the visible Plans-page external link with a local fixture.

## Verification

Run from a clean checkout:

```sh
npm ci
npm test
npm run build
cargo fmt --all -- --check
cargo clippy --all-targets --locked -- -D warnings
cargo build --release --locked
npm run test:container-identity
npm run test:runtime-policy
npm run test:e2e
npm run test:claims -- --grep @claim:external-checkout
npm run deploy
npm run verify:live-topology
npm run test:all-claims
```

Observed before deployment of this commit:

| Check | Evidence |
| --- | --- |
| Clean install | `npm ci`: 86 packages; 0 reported vulnerabilities |
| Unit, integration, and deployment fixtures | `npm test`: 5 TypeScript tests, 13 Rust tests, durable deployment, durable workflow, and topology fixtures pass |
| Production frontend build | 38.93 kB JS / 12.43 kB gzip; 19.42 kB CSS / 5.19 kB gzip |
| Rust quality and runtime policy | format check, strict Clippy, locked release build, build identity, and unprivileged durable-snapshot test pass |
| Desktop and 390 px browser coverage | `npm run test:e2e` passes the app and all claim groups; desktop has 9 app tests plus 19 claims, mobile covers its applicable app and claim tests |
| Checkout recovery | exact `@claim:external-checkout`: catalog 200, product price `3900` USD cents, checkout 303 to `checkout.dodopayments.com` |

The final deployment command and post-deploy topology check are run against
the exact committed source revision. They require one active, healthy,
running, ready replica; the `checkin-data` Azure File volume at `/app/data`;
the expected read-write share; the product custom domain; and a matching
`/health` build SHA. The durable deploy also proves a create, submit, review,
receipt, and repeated private-link reads survive a new production revision.

## Privacy, accessibility, and operations

- No analytics, advertising, model, or font-CDN requests are added. Checkout
  is a user-initiated external link to the designated Sociobot/Dodo merchant.
- Browser coverage includes desktop and 390 px mobile, keyboard flows, axe
  serious/critical checks, 200% mobile text resize, reduced motion, offline
  demo reload, demo isolation/reset, and same-origin privacy boundaries.
- The worker's `/opt/fleet/lib/verify-url.sh` is run against the live landing
  page during the post-deploy audit for title, language, main landmark, image
  alt text, screenshots, and console errors.

## Known gaps

None. The product intentionally has no accounts, automated judgment, or model
feature; no Entra or AI identity check applies. The only external dependency
in the paid path is the documented Sociobot/Dodo checkout service, whose live
availability is asserted by the declared claim.
