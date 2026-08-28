# Accessible Explanation Check-in

Collect student reasoning with a low-stakes text or voice check-in for teachers.
Teachers use it when they want students to explain a choice after classwork.

## Try it

Open [`/demo`](https://accessible-explanation-checkin.sociobot.in/demo) for a populated teacher review. The demo saves edits only in a separate browser key. Use **Reset demo** to restore the sample. Use **Start for real** to create a private check-in.

## Run and test

Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain.

```sh
npm ci
npm test
npm run build
npm run test:e2e
cargo build --release --locked
PORT=8080 cargo run
```

Run every public claim check from a clean checkout:

```sh
for test in $(jq -r '.[].test' .factory/claims.json); do eval "$test"; done
```

The app listens on `PORT` and defaults to `8080`. Its frontend build is in `dist/`. Local records use `data/` unless configuration supplies another path.

## Deploy

This is a single-container Rust and Vite application. Build it with the root `Dockerfile`. The runtime serves the frontend and API on port 8080 as the non-root `checkin` user.

Use `scripts/deploy-durable-container.sh` for Container Apps. It mounts a product-specific Azure File share at `/app/data` and uses one SQLite replica.

See [privacy](https://accessible-explanation-checkin.sociobot.in/privacy), [terms](https://accessible-explanation-checkin.sociobot.in/terms), [demo notes](.factory/demo.md), and the [MIT license](LICENSE).
