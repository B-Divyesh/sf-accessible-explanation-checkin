#!/usr/bin/env bash
set -euo pipefail

echo 'Building the production frontend and release server for the runtime policy claim'
npm run build >/dev/null
cargo build --release --locked >/dev/null

runtime_tmp=$(mktemp -d)
runtime_pid=''
cleanup() {
  if [ -n "$runtime_pid" ]; then
    kill "$runtime_pid" 2>/dev/null || true
    wait "$runtime_pid" 2>/dev/null || true
  fi
  rm -rf "$runtime_tmp"
}
trap cleanup EXIT
chmod 0777 "$runtime_tmp"
mkdir -p "$runtime_tmp/app" "$runtime_tmp/uploads" "$runtime_tmp/durable"
cp target/release/accessible-explanation-checkin "$runtime_tmp/app/server"
cp -R dist "$runtime_tmp/app/dist"
chmod 0755 "$runtime_tmp/app" "$runtime_tmp/app/server" "$runtime_tmp/app/dist"
chmod 0777 "$runtime_tmp/uploads" "$runtime_tmp/durable"

runtime_stage=$(sed -n '/^FROM debian:bookworm-slim AS runtime$/,$p' Dockerfile)
grep -qx 'USER checkin' <<<"$runtime_stage"
if tail -n 8 Dockerfile | grep -qx 'USER root'; then
  echo 'FAIL: the final image selects root' >&2
  exit 1
fi

setpriv --reuid=65534 --regid=65534 --clear-groups env \
  PORT=18193 \
  DATA_DIR="$runtime_tmp/durable" \
  DIST_DIR="$runtime_tmp/app/dist" \
  BUILD_SHA=claim-runtime \
  "$runtime_tmp/app/server" >"$runtime_tmp/server.log" 2>&1 &
runtime_pid=$!

for _ in $(seq 1 80); do
  if curl --fail --silent http://127.0.0.1:18193/health >"$runtime_tmp/health.json"; then
    break
  fi
  sleep 0.1
done

grep -Fq '"build_sha":"claim-runtime"' "$runtime_tmp/health.json"
curl --fail --silent \
  -H 'content-type: application/json' \
  -d '{"title":"Non-root proof","prompt":"Explain one choice.","voice_retention_days":1}' \
  http://127.0.0.1:18193/api/checkins >"$runtime_tmp/create.json"
grep -Fq 'student_token' "$runtime_tmp/create.json"
test -s "$runtime_tmp/durable/checkins.db"
# The server process runs through setpriv as UID 65534. A durable SQLite write
# is stronger and less racy proof than inspecting setpriv's transient wrapper
# process in /proc.
test "$(stat -c '%u' "$runtime_tmp/durable/checkins.db")" = '65534'

echo 'PASS @claim:runtime-container-policy: release server ran non-root and wrote its durable SQLite database'
