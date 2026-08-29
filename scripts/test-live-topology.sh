#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
checker="$repo_root/scripts/verify-live-topology.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/state"

cat > "$test_dir/bin/az" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
args="$*"
case "$args" in
  'containerapp show '*) cat "$MOCK_STATE_DIR/topology.json" ;;
  'containerapp env storage show '*) cat "$MOCK_STATE_DIR/storage.json" ;;
  'containerapp revision list '*) cat "$MOCK_STATE_DIR/revisions.json" ;;
  'containerapp replica list '*) cat "$MOCK_STATE_DIR/replicas.json" ;;
  *) echo "unexpected az command: $args" >&2; exit 1 ;;
esac
MOCK

cat > "$test_dir/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"build_sha":"repair-sha","status":"ok"}'
MOCK
chmod +x "$test_dir/bin/az" "$test_dir/bin/curl"

# Exact production shape reported by independent verification 8. The gate
# must fail before a release can claim durable SQLite storage.
cat > "$test_dir/state/topology.json" <<'JSON'
{"properties":{"latestRevisionName":"app--0000065","latestReadyRevisionName":"app--0000065","template":{"scale":{"minReplicas":1,"maxReplicas":3},"volumes":null,"containers":[{"name":"app","image":"registry/app:repair-sha","volumeMounts":null}]}}}
JSON
cat > "$test_dir/state/storage.json" <<'JSON'
{"properties":{"azureFile":{"accessMode":"ReadWrite","shareName":"durable-share"}}}
JSON
cat > "$test_dir/state/revisions.json" <<'JSON'
[{"name":"app--0000065","properties":{"active":true}}]
JSON
cat > "$test_dir/state/replicas.json" <<'JSON'
[{"name":"replica-a","properties":{"runningState":"Running"}},{"name":"replica-b","properties":{"runningState":"Running"}}]
JSON

if MOCK_STATE_DIR="$test_dir/state" AZ_BIN="$test_dir/bin/az" CURL_BIN="$test_dir/bin/curl" \
  "$checker" https://example.test app group repair-sha durable durable-share \
  >"$test_dir/bad.out" 2>&1; then
  echo 'live topology gate accepted the verifier 8 unmounted multi-replica topology' >&2
  exit 1
fi
grep -Fq 'expected minReplicas=maxReplicas=1; observed minReplicas=1 maxReplicas=3' \
  "$test_dir/bad.out"

cat > "$test_dir/state/topology.json" <<'JSON'
{"properties":{"latestRevisionName":"app--0000066","latestReadyRevisionName":"app--0000066","template":{"scale":{"minReplicas":1,"maxReplicas":1},"volumes":[{"name":"checkin-data","storageType":"AzureFile","storageName":"durable"}],"containers":[{"name":"app","image":"registry/app:repair-sha","volumeMounts":[{"volumeName":"checkin-data","mountPath":"/app/data"}]}]}}}
JSON
cat > "$test_dir/state/revisions.json" <<'JSON'
[{"name":"app--0000065","properties":{"active":false}},{"name":"app--0000066","properties":{"active":true}}]
JSON
cat > "$test_dir/state/replicas.json" <<'JSON'
[{"name":"replica-c","properties":{"runningState":"Running"}}]
JSON

output=$(MOCK_STATE_DIR="$test_dir/state" AZ_BIN="$test_dir/bin/az" CURL_BIN="$test_dir/bin/curl" \
  "$checker" https://example.test app group repair-sha durable durable-share)
jq -e '
  .result == "PASS"
  and .revision == "app--0000066"
  and .topology.min_replicas == 1
  and .topology.max_replicas == 1
  and .topology.active_revisions == 1
  and .topology.running_replicas == 1
  and .topology.mount_path == "/app/data"
' >/dev/null <<<"$output"

echo 'PASS: live topology gate rejects verifier 8 state and accepts one mounted SQLite replica'
