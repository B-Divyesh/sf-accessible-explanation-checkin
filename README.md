# Accessible Explanation Check-in

Collect student reasoning with a low-stakes text or voice check-in for teachers.
Teachers use it when they want students to explain a choice after classwork.

## Try it

Open [`/demo`](https://accessible-explanation-checkin.sociobot.in/demo) for a populated teacher review. The demo saves edits only in a separate browser key. Use **Reset demo** to restore the sample. **Start for real** discards sample edits before creating a private check-in.

## Run and test

Requirements: Node 22+, npm, Rust 1.89+, and a C toolchain.

```sh
npm ci
npm test
npm run build
npm run test:e2e
npm run test:claims
npm run test:all-claims
npm run test:runtime-policy
cargo build --release --locked
PORT=8080 cargo run
```

`npm run test:all-claims` reads `.factory/claims.json` and runs every listed
command separately. It stops at the first failure.

The app listens on `PORT` and defaults to `8080`. Its frontend build is in `dist/`. Local records use `data/` unless configuration supplies another path.

## Deploy

This is a single-container Rust and Vite application. Build it with the root `Dockerfile`.

The image declares port 8080 and the non-root `checkin` user. Its claim test executes the release server under an unprivileged UID.

Use `scripts/deploy-durable-container.sh` for Container Apps. It mounts a product-specific Azure File share at `/app/data`.

The deployment uses one SQLite replica. The deployment gate checks private links, submission, and teacher review. It repeats those checks after replacing the production revision. The deployment test checks the storage mount, one-replica setting, and repeated private-link reads.

See [privacy](https://accessible-explanation-checkin.sociobot.in/privacy), [terms](https://accessible-explanation-checkin.sociobot.in/terms), [demo notes](.factory/demo.md), and the [MIT license](LICENSE).
