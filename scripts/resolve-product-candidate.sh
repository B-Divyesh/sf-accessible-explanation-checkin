#!/usr/bin/env bash
# Resolve the latest commit that changed a shipped or acceptance-critical
# product file. Reviewer notes, verification evidence, and graph indexes do
# not create a new product candidate and must not invalidate the live build.
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo=${1:-$(cd -- "$script_dir/.." && pwd -P)}

git -C "$repo" log -1 --format=%H -- \
  AGENTS.md \
  Cargo.lock \
  Cargo.toml \
  Dockerfile \
  LICENSE \
  README.md \
  package-lock.json \
  package.json \
  frontend \
  migrations \
  scripts \
  src \
  .factory/brief.json \
  .factory/claims.json \
  .factory/demo.md \
  .factory/design.md
