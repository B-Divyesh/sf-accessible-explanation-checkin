# Accessible Explanation Check-in

A keyboard- and screen-reader-first classroom utility for collecting a short
student explanation, confidence rating, and optional voice note. Teachers get
plain review tags and private notes rather than an AI-authorship or misconduct
score. Students receive a private, printable receipt.

It is designed for teachers working in AI-pervasive classes who need usable
evidence for a humane follow-up conversation. It does **not** detect AI,
proctor students, verify identity, or grade work.

## Product flow

1. A teacher creates one prompt and chooses a voice deletion schedule.
2. The service returns separate unguessable student and teacher-review links.
3. Each student responds in text, optional voice, or both and selects confidence.
4. The teacher reviews, tags, adds a private note, exports CSV, and can delete
   voice immediately. Voice also expires automatically.
5. The student keeps a receipt page and can print/save it as PDF.

Free check-ins accept 35 responses and 1–7 day voice retention. Classroom Plus
is a $39 one-time license unlock for up to 500 responses and 1–365 day voice
retention. Checkout and verification use the Sociobot billing API; no payment
provider is embedded. Accessibility and exports are never gated.

## Stack

- Vite + strict TypeScript, with no runtime UI framework or third-party script
- Rust 2021, Axum, Tokio and SQLx/SQLite
- One container serves the API and built frontend on `PORT` (default `8080`)
- Local filesystem voice storage with hourly expiry cleanup

## Develop

Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain.

```sh
npm ci
npm run dev
```

Vite runs on `http://localhost:5173` and proxies API requests to the Rust server
on `http://localhost:8080`. Local records are written under `data/`.

## Test and build

```sh
npm test
npm run build       # reproducible frontend output at dist/index.html
cargo build --release --locked
docker build -t explanation-checkin .
docker run --rm -p 8080:8080 -v checkin-data:/app/data explanation-checkin
```

`npm test` runs the TypeScript unit tests and Rust unit/integration API flow.
The integration test creates a check-in, submits an explanation, reads and
updates teacher review, loads a receipt, exports CSV, deletes voice state, and
checks health.

For an HTTP load smoke against a running server:

```sh
npx autocannon -c 10 -a 100 http://localhost:8080/health
```

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `8080` | HTTP listen port |
| `DATABASE_URL` | `sqlite:data/checkins.db?mode=rwc` | SQLite URL |
| `UPLOADS_DIR` | `data/uploads` | Ephemeral voice-file directory |
| `DIST_DIR` | `dist` | Built frontend directory |
| `BUILD_SHA` | `development` | Value returned from `/health` |
| `BILLING_BASE_URL` | `https://api.sociobot.in` | Server-side license verifier |
| `VITE_BILLING_BASE_URL` | `https://api.sociobot.in` | Checkout/browser verifier at build time |

The product defaults to the production Sociobot billing service. A staging build
may explicitly supply `https://pilot-api.sociobot.in` for both variables. The
product slug is used in URLs; no product ID is hardcoded.

## Privacy and operations

There is no analytics SDK, advertising, remote font, or third-party runtime
script. Private links are bearer secrets and must be protected. Back up the
SQLite database and the voice directory together. Mount `/app/data` on durable
storage. For the factory Container Apps deployment, use
`scripts/deploy-durable-container.sh`: it creates/uses a product-specific
Azure File share, mounts it at `/app/data`, and pins the SQLite service to one
replica. Deploy behind TLS; the application sends CSP, HSTS, Permissions
Policy, no-sniff, no-referrer and cache-policy headers, applies a burst rate
limit, and logs structured JSON.

See [`/privacy`](https://accessible-explanation-checkin.sociobot.in/privacy),
[`/terms`](https://accessible-explanation-checkin.sociobot.in/terms),
[`.factory/design.md`](.factory/design.md), and
[`.factory/handoff.md`](.factory/handoff.md).

## License

MIT — see [LICENSE](LICENSE).
