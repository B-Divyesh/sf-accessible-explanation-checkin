# Handoff — adversarial review 3

## Work completed

Performed the requested no-code-change adversarial review and recorded it in
`.factory/review-3.md`. The review used fresh 390 px and desktop browser
contexts, exercised the isolated demo, crawled the public routes and links,
read the brief/design/history, and audited all landing and README reader copy.

## Verification

In a fresh clone, `npm ci` failed because no lockfile is committed. After
`npm install` only to permit inspection, these passed: `npm test`, `npm run
build`, `npm run test:e2e` (42 tests), `npm run test:claims` (22 passed; six
expected mobile skips), `npm run test:runtime-policy`,
`npm run test:deployment-policy`, and the two direct Rust claim tests.

Live demo verification confirmed a populated three-response review, the
visible demo banner/reset/start-real controls, `demo:`-only browser storage,
working reset, same-origin-only requests, and no console errors. The live 404
and internal routes were also checked.

## Known gaps / next steps

The review verdict is **FAIL**. The live Classroom Plus checkout URL returns
HTTP 404, even though the local checkout claim test passes through a mocked
fixture. Configure the real checkout and add a safe non-404 production
preflight/integration check. Commit `package-lock.json` so the documented
`npm ci` clean-clone path works. Re-run review 3's live link crawl and full
claim verification after those fixes.
