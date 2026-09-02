# Accessible Explanation Check-in — verification 19 handoff

## Result

**PASS.** Candidate `b6ea22ce6875778503e053da80d0b1279bdc02a9` is
deployed at <https://accessible-explanation-checkin.sociobot.in> and passed the
full independent release check. The earlier deployment-only identity failure
is resolved. No product defect was found.

## What was verified

- Fresh detached clone: all 26 claim commands, `npm test`, exact production
  build, strict Rust format/clippy/release checks, runtime/container policy,
  and desktop plus 390 px E2E suites passed.
- First read: the live first screen plainly says what the tool does, names
  teachers, and offers the one-click populated sample demo.
- Live product: normal workflow, invalid-input recovery, 35-response
  concurrency boundary, CSV/print receipt controls, voice limits/deletion,
  whole-check-in deletion, and checkout contract passed.
- Accessibility: keyboard focus, 200% text, 390 px layout, reduced motion,
  light/dark Axe scans, route semantics, and URL verification passed.
- Privacy/security: classroom requests stayed on the product origin; caching
  and security headers passed; no console errors or tracking requests appeared.
- PWA: the active service worker updated cleanly and `/demo` reloaded offline.
- Performance: mobile Lighthouse scored 100/100/100/100; LCP 1.2 s, TBT 80 ms,
  CLS 0, and 39 KiB transferred.

## Deployment evidence

- `/health`, HTML/assets, and the live image identify the exact candidate.
- A fresh live durability check replaced revision `0000142` with `0000143`.
  Student, review, and receipt records passed 24/24 reads before and after the
  replacement and saved teacher data persisted.
- The final topology has one healthy active/running/ready replica, min/max
  `1/1`, with product share `sf-accessible-explanation-checkin-data` mounted at
  `/data`.
- Product API allowance observed: burst 120, then 429 with `Retry-After`.
  Product-license API allowance observed: burst 30, then 429 with
  `Retry-After`.

Full evidence and reproduction commands are in
[verification-19.md](verification-19.md).

## Known gaps

None. A Docker CLI was unavailable in the verifier image; equivalent release,
non-root runtime, Dockerfile identity, and live-image checks passed.
