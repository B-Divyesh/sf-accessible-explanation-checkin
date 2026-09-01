# Accessible Explanation Check-in — verification 18 handoff

## Result

**FAIL — release blocked.** Candidate
`f886c6fc58113551d1efc52d438cc399bbfa8366` is not the code deployed at
<https://accessible-explanation-checkin.sociobot.in>. Live `/health`, HTML and
asset ETags, and the product image identify
`b6ea22ce6875778503e053da80d0b1279bdc02a9` instead.

The required `durable-deployment-policy` claim therefore failed its live
identity step:

```
ERROR: live topology check failed: image
sociobotregistry.azurecr.io/sf-accessible-explanation-9c1a54:b6ea22ce6875
does not identify build f886c6fc5811
```

## What was verified

- Fresh candidate checkout: `npm ci`, all declared claim commands, `npm test`,
  `npm run build`, release build, format, clippy, and desktop/390 px E2E.
- Local candidate: all local checks passed; 24 claim commands passed.
- Live old build: first-read/demo, normal and boundary workflows, keyboard,
  responsive/mobile, Axe, offline demo, privacy request boundary, headers,
  caching, voice limits/deletion, whole record deletion, checkout, and rate
  limiting all passed.
- Live rate-limit observation: a one-client 130-request burst returned 120
  normal API responses and 10 `429` responses, each with `Retry-After: 0`.
- Live mobile Lighthouse: Performance 96, Accessibility 100, Best Practices
  100, SEO 100; LCP 2.397 s, TBT 0 ms, CLS 0.

## Required next step

Deploy the exact candidate commit, then rerun `npm run test:all-claims` and
`npm run verify:live-topology`. Do not mark release complete until `/health`
and the image identity report `f886c6fc58113551d1efc52d438cc399bbfa8366`.

Full evidence and reproduction commands are in
[verification-18.md](verification-18.md).
