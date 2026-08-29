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

# Exact production shape reported by independent verification 10: the right
# image and health identity were active, but two ready ephemeral replicas
# had no Azure File mount. Each independently unsafe dimension is rejected.
cat > "$test_dir/state/topology.json" <<'JSON'
{"properties":{"latestRevisionName":"app--0000082","latestReadyRevisionName":"app--0000082","template":{"scale":{"minReplicas":1,"maxReplicas":3},"volumes":null,"containers":[{"name":"app","image":"registry/app:repair-sha","volumeMounts":null}]}}}
JSON
cat > "$test_dir/state/storage.json" <<'JSON'
{"properties":{"azureFile":{"accessMode":"ReadWrite","shareName":"durable-share"}}}
JSON
cat > "$test_dir/state/revisions.json" <<'JSON'
[{"name":"app--0000082","properties":{"active":true,"healthState":"Healthy","provisioningState":"Provisioned","runningState":"RunningAtMaxScale"}}]
JSON
cat > "$test_dir/state/replicas.json" <<'JSON'
[{"name":"replica-a","properties":{"runningState":"Running","containers":[{"name":"app","ready":true,"started":true,"runningState":"Running"}]}},{"name":"replica-b","properties":{"runningState":"Running","containers":[{"name":"app","ready":true,"started":true,"runningState":"Running"}]}}]
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
{"properties":{"latestRevisionName":"app--0000082","latestReadyRevisionName":"app--0000082","template":{"scale":{"minReplicas":1,"maxReplicas":1},"volumes":null,"containers":[{"name":"app","image":"registry/app:repair-sha","volumeMounts":null}]}}}
JSON

if MOCK_STATE_DIR="$test_dir/state" AZ_BIN="$test_dir/bin/az" CURL_BIN="$test_dir/bin/curl" \
  "$checker" https://example.test app group repair-sha durable durable-share \
  >"$test_dir/unmounted.out" 2>&1; then
  echo 'live topology gate accepted verification 10 without /app/data' >&2
  exit 1
fi
grep -Fq 'expected the checkin-data Azure File volume mounted at /app/data' \
  "$test_dir/unmounted.out"

cat > "$test_dir/state/topology.json" <<'JSON'
{"properties":{"latestRevisionName":"app--0000083","latestReadyRevisionName":"app--0000083","template":{"scale":{"minReplicas":1,"maxReplicas":1},"volumes":[{"name":"checkin-data","storageType":"AzureFile","storageName":"durable"}],"containers":[{"name":"app","image":"registry/app:repair-sha","volumeMounts":[{"volumeName":"checkin-data","mountPath":"/app/data"}]}]}}}
JSON
cat > "$test_dir/state/revisions.json" <<'JSON'
[{"name":"app--0000082","properties":{"active":false,"healthState":"Healthy","provisioningState":"Provisioned","runningState":"Stopped"}},{"name":"app--0000083","properties":{"active":true,"healthState":"Unhealthy","provisioningState":"Provisioned","runningState":"Degraded"}}]
JSON

if MOCK_STATE_DIR="$test_dir/state" AZ_BIN="$test_dir/bin/az" CURL_BIN="$test_dir/bin/curl" \
  "$checker" https://example.test app group repair-sha durable durable-share \
  >"$test_dir/revision.out" 2>&1; then
  echo 'live topology gate accepted a non-healthy, non-running revision' >&2
  exit 1
fi
grep -Fq 'is not the sole active, healthy, running revision' "$test_dir/revision.out"

cat > "$test_dir/state/revisions.json" <<'JSON'
[{"name":"app--0000082","properties":{"active":false,"healthState":"Healthy","provisioningState":"Provisioned","runningState":"Stopped"}},{"name":"app--0000083","properties":{"active":true,"healthState":"Healthy","provisioningState":"Provisioned","runningState":"Running"}}]
JSON

if MOCK_STATE_DIR="$test_dir/state" AZ_BIN="$test_dir/bin/az" CURL_BIN="$test_dir/bin/curl" \
  "$checker" https://example.test app group repair-sha durable durable-share \
  >"$test_dir/replicas.out" 2>&1; then
  echo 'live topology gate accepted verification 10 with multiple ready replicas' >&2
  exit 1
fi
grep -Fq 'expected one running replica; observed 2' "$test_dir/replicas.out"

cat > "$test_dir/state/replicas.json" <<'JSON'
[{"name":"replica-d","properties":{"runningState":"Running","containers":[{"name":"app","ready":true,"started":true,"runningState":"Running"}]}}]
JSON

output=$(MOCK_STATE_DIR="$test_dir/state" AZ_BIN="$test_dir/bin/az" CURL_BIN="$test_dir/bin/curl" \
  "$checker" https://example.test app group repair-sha durable durable-share)
jq -e '
  .result == "PASS"
  and .revision == "app--0000083"
  and .topology.min_replicas == 1
  and .topology.max_replicas == 1
  and .topology.active_revisions == 1
  and .topology.running_replicas == 1
  and .topology.ready_replicas == 1
  and .topology.revision_health == "Healthy"
  and .topology.mount_path == "/app/data"
' >/dev/null <<<"$output"

echo 'PASS: live topology gate rejects verification 10 and accepts one healthy mounted SQLite replica'
