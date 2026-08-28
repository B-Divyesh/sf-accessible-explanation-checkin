#!/usr/bin/env bash
# The deployment helper passes BUILD_SHA during the ACR build. Keep it in the
# runtime stage so /health identifies the image actually running in production.
set -euo pipefail

dockerfile=${1:-Dockerfile}
runtime_stage=$(sed -n '/^FROM debian:bookworm-slim AS runtime$/,$p' "$dockerfile")

grep -qx 'ARG BUILD_SHA=development' <<<"$runtime_stage"
grep -Fqx 'ENV PORT=8080 DATABASE_URL=sqlite:data/checkins.db?mode=rwc UPLOADS_DIR=data/uploads DIST_DIR=dist BUILD_SHA=${BUILD_SHA}' <<<"$runtime_stage"

echo 'PASS: runtime image accepts BUILD_SHA and exposes it to /health'
