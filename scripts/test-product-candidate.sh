#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
resolver="$repo_root/scripts/resolve-product-candidate.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
fixture="$test_dir/repo"

git init --quiet "$fixture"
git -C "$fixture" config user.name "Candidate test"
git -C "$fixture" config user.email "candidate-test@example.invalid"
mkdir -p "$fixture/scripts" "$fixture/frontend/src" "$fixture/.factory" "$fixture/graphify-out"
cp "$resolver" "$fixture/scripts/resolve-product-candidate.sh"
printf '%s\n' 'export const version = 1;' > "$fixture/frontend/src/main.ts"
printf '%s\n' '[]' > "$fixture/.factory/claims.json"
git -C "$fixture" add scripts frontend .factory/claims.json
git -C "$fixture" commit --quiet -m 'product candidate'
candidate=$(git -C "$fixture" rev-parse HEAD)

printf '%s\n' '# Reviewer notes only' > "$fixture/.factory/review-8.md"
printf '%s\n' '{}' > "$fixture/graphify-out/graph.json"
git -C "$fixture" add .factory/review-8.md graphify-out/graph.json
git -C "$fixture" commit --quiet -m 'reviewer-only commit'
reviewer=$(git -C "$fixture" rev-parse HEAD)
resolved=$(bash "$fixture/scripts/resolve-product-candidate.sh" "$fixture")
[[ "$resolved" == "$candidate" ]] || {
  echo "reviewer-only commit changed candidate from $candidate to $resolved" >&2
  exit 1
}
[[ "$resolved" != "$reviewer" ]] || {
  echo "reviewer-only commit was incorrectly selected as the product candidate" >&2
  exit 1
}

printf '%s\n' 'export const version = 2;' > "$fixture/frontend/src/main.ts"
git -C "$fixture" add frontend/src/main.ts
git -C "$fixture" commit --quiet -m 'product repair'
repair=$(git -C "$fixture" rev-parse HEAD)
resolved=$(bash "$fixture/scripts/resolve-product-candidate.sh" "$fixture")
[[ "$resolved" == "$repair" ]] || {
  echo "product repair did not advance candidate to $repair" >&2
  exit 1
}

echo 'PASS: verifier-only commits preserve the product candidate while shipped changes advance it'
