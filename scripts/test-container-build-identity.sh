#!/usr/bin/env bash
# The deployment helper passes BUILD_SHA during the ACR build. Keep it in the
# runtime stage so /health identifies the image actually running in production.
set -euo pipefail

dockerfile=${1:-Dockerfile}
runtime_stage=$(sed -n '/^FROM debian:bookworm-slim AS runtime$/,$p' "$dockerfile")

grep -qx 'ARG BUILD_SHA=development' <<<"$runtime_stage"
grep -Fqx 'ENV PORT=8080 BUILD_SHA=${BUILD_SHA}' <<<"$runtime_stage"
grep -Fq 'mkdir -p /data/uploads' <<<"$runtime_stage"
grep -qx 'USER checkin' <<<"$runtime_stage"
if tail -n 8 "$dockerfile" | grep -qx 'USER root'; then
  echo 'FAIL: runtime image must not run as root' >&2
  exit 1
fi

echo 'PASS: runtime image accepts BUILD_SHA, uses /data for durable state, exposes it to /health, and runs as checkin'
