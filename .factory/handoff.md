# Accessible Explanation Check-in — review 8 handoff

## Result

**FAIL.** This reviewer changed documentation only. The full findings are in
[review-8.md](review-8.md).

## What was checked

- Fresh 390 px and desktop live contexts: cold first read, console errors,
  metadata, route focus/history, navigation links, and designed 404.
- One-click live demo: populated sample review, reset, demo-key isolation,
  start-real disposal, and request-origin boundary.
- Fresh GitHub clone at `5a5cf395…`: installed with `npm ci`, then invoked the
  claims manifest. The durable live-topology assertion fails because it expects
  the verifier commit while the deployed product remains `b6ea22ce…`.
- Landing and README copy audit with word counts and claim cross-check.

## Remaining work

1. Repair the durable-deployment claim command so it succeeds from the
   assigned clean clone (F-6-1).
2. Add a claim/test for the public 1,200-character prompt limit (F-8-1).
3. Standardize “judgment” spelling (F-8-2).

## How to reproduce

```sh
npm ci
npm run test:all-claims
npm run verify:live-topology
```

The last command currently reports that live build `b6ea22ce…` does not match
clean-clone head `5a5cf395…`.
