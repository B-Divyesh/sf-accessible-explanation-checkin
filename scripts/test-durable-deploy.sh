#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
script=${1:-scripts/deploy-durable-container.sh}
if [[ "$script" != /* ]]; then
  script="$repo_root/$script"
fi

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin"

cat > "$test_dir/fleet-deploy" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$MOCK_STATE_DIR/fleet-args"
MOCK

cat > "$test_dir/live-checker" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$MOCK_STATE_DIR/live-checker-args"
# The production durability check creates a replacement revision.  Record that
# moment so this fixture proves the final topology gate runs after it.
: > "$MOCK_STATE_DIR/durability-workflow-finished"
echo '{"result":"PASS"}'
MOCK

cat > "$test_dir/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '{"build_sha":"%s","status":"ok"}\n' "${MOCK_BUILD_SHA:?}"
MOCK

cat > "$test_dir/bin/az" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
args="$*"

if [[ "$args" == "storage account keys list"* ]]; then
  printf '%s\n' 'mock-storage-key'
elif [[ "$args" == "storage share create"* || "$args" == "containerapp env storage set"* ]]; then
  exit 0
elif [[ "$args" == "containerapp env storage show"* ]]; then
  cat "$MOCK_STATE_DIR/storage.json"
elif [[ "$args" == "account show"* ]]; then
  printf '%s\n' '00000000-0000-0000-0000-000000000000'
elif [[ "$args" == "containerapp revision deactivate"* ]]; then
  printf '%s\n' "$args" > "$MOCK_STATE_DIR/deactivated"
elif [[ "$args" == "containerapp revision list"* && "$args" == *"[?properties.active].name"* ]]; then
  if [[ -f "$MOCK_STATE_DIR/deactivated" ]]; then
    printf '%s\n' 'sf-accessible-explanation-9c1a54--0000002'
  else
    printf '%s\n' 'sf-accessible-explanation-9c1a54--0000001' 'sf-accessible-explanation-9c1a54--0000002'
  fi
elif [[ "$args" == "containerapp revision list"* && "$args" == *"length([?properties.active])"* ]]; then
  printf '%s\n' '1'
elif [[ "$args" == "containerapp revision list"* ]]; then
  cat "$MOCK_STATE_DIR/revisions.json"
elif [[ "$args" == "containerapp replica list"* && "$args" == *"--output json"* ]]; then
  cat "$MOCK_STATE_DIR/replicas.json"
elif [[ "$args" == "containerapp replica list"* ]]; then
  printf '%s\n' '1'
elif [[ "$args" == "rest --method patch"* ]]; then
  body=''
  while (($#)); do
    if [[ "$1" == "--body" ]]; then
      shift
      body=$1
      break
    fi
    shift
  done
  [[ -n "$body" ]]
  printf '%s\n' "$body" > "$MOCK_STATE_DIR/patch.json"
  if [[ "${MOCK_APPLY_PATCH:-1}" == 1 ]]; then
    : > "$MOCK_STATE_DIR/patched"
  fi
elif [[ "$args" == "containerapp show"* ]]; then
  if [[ -f "$MOCK_STATE_DIR/patched" && "${MOCK_REGRESS_AFTER_DURABILITY:-0}" == 1 && -f "$MOCK_STATE_DIR/durability-workflow-finished" ]]; then
    cat "$MOCK_STATE_DIR/regressed-app.json"
  elif [[ -f "$MOCK_STATE_DIR/patched" ]]; then
    cat "$MOCK_STATE_DIR/patched-app.json"
  else
    cat "$MOCK_STATE_DIR/stateless-app.json"
  fi
else
  echo "unexpected az command: $args" >&2
  exit 1
fi
MOCK

chmod +x "$test_dir/fleet-deploy" "$test_dir/live-checker" \
  "$test_dir/bin/az" "$test_dir/bin/curl"

test_sha=$(git -C "$repo_root" rev-parse HEAD)

cat > "$test_dir/stateless-app.json" <<'JSON'
{"properties":{"latestRevisionName":"sf-accessible-explanation-9c1a54--0000001","latestReadyRevisionName":"sf-accessible-explanation-9c1a54--0000001","template":{"scale":{"minReplicas":1,"maxReplicas":3},"volumes":null,"containers":[{"name":"app","image":"example.invalid/app:before"}]}}}
JSON

cat > "$test_dir/patched-app.json" <<JSON
{"name":"sf-accessible-explanation-9c1a54","properties":{"configuration":{"ingress":{"customDomains":[{"name":"accessible-explanation-checkin.sociobot.in","bindingType":"SniEnabled"}]}},"latestRevisionName":"sf-accessible-explanation-9c1a54--0000002","latestReadyRevisionName":"sf-accessible-explanation-9c1a54--0000002","template":{"scale":{"minReplicas":1,"maxReplicas":1},"volumes":[{"name":"checkin-data","storageType":"AzureFile","storageName":"aec-accessible-explanati-9c1a54"}],"containers":[{"name":"app","image":"example.invalid/app:${test_sha:0:12}","volumeMounts":[{"volumeName":"checkin-data","mountPath":"/app/data"}]}]}}}
JSON

cat > "$test_dir/regressed-app.json" <<JSON
{"name":"sf-accessible-explanation-9c1a54","properties":{"configuration":{"ingress":{"customDomains":[{"name":"accessible-explanation-checkin.sociobot.in","bindingType":"SniEnabled"}]}},"latestRevisionName":"sf-accessible-explanation-9c1a54--0000003","latestReadyRevisionName":"sf-accessible-explanation-9c1a54--0000003","template":{"scale":{"minReplicas":1,"maxReplicas":3},"volumes":[{"name":"checkin-data","storageType":"AzureFile","storageName":"aec-accessible-explanati-9c1a54"}],"containers":[{"name":"app","image":"example.invalid/app:${test_sha:0:12}","volumeMounts":[{"volumeName":"checkin-data","mountPath":"/app/data"}]}]}}}
JSON

cat > "$test_dir/storage.json" <<'JSON'
{"properties":{"azureFile":{"accessMode":"ReadWrite","shareName":"sf-accessible-explanation-checkin-data"}}}
JSON

cat > "$test_dir/revisions.json" <<'JSON'
[{"name":"sf-accessible-explanation-9c1a54--0000002","properties":{"active":true,"healthState":"Healthy","provisioningState":"Provisioned","runningState":"Running"}}]
JSON

cat > "$test_dir/replicas.json" <<'JSON'
[{"name":"replica-a","properties":{"runningState":"Running","containers":[{"name":"app","ready":true,"started":true,"runningState":"Running"}]}}]
JSON

# The factory's generic Container Apps helper deliberately creates a stateless
# 1–3 replica template. The public deployment command must therefore run the
# durable wrapper, rather than exposing that helper as this product's deploy
# entry point. Execute the actual package command against that unsafe fixture.
package_output=$(cd "$repo_root" && \
  PATH="$test_dir/bin:$PATH" \
  MOCK_STATE_DIR="$test_dir" \
  MOCK_BUILD_SHA="$test_sha" \
  AZ_BIN="$test_dir/bin/az" \
  CURL_BIN="$test_dir/bin/curl" \
  FLEET_DEPLOY_CONTAINER_HELPER="$test_dir/fleet-deploy" \
  LIVE_DURABILITY_CHECKER="$test_dir/live-checker" \
  LIVE_TOPOLOGY_CHECKER="$repo_root/scripts/verify-live-topology.sh" \
  DEPLOY_VERIFY_ATTEMPTS=1 \
  npm run deploy --silent)

jq -e '
  .properties.template.scale == {minReplicas: 1, maxReplicas: 1}
  and (.properties.template.volumes[] | select(.name == "checkin-data") | .storageType) == "AzureFile"
  and (.properties.template.containers[] | select(.name == "app") | .volumeMounts[] | select(.mountPath == "/app/data") | .volumeName) == "checkin-data"
' "$test_dir/patch.json" >/dev/null
[[ "$package_output" == *"PASS: deployed and verified sf-accessible-explanation-9c1a54"* ]]
[[ "$package_output" == *'"result": "PASS"'* ]]
[[ -f "$test_dir/durability-workflow-finished" ]]

rm -f "$test_dir/durability-workflow-finished"
output=$(PATH="$test_dir/bin:$PATH" \
  MOCK_STATE_DIR="$test_dir" \
  MOCK_BUILD_SHA="$test_sha" \
  AZ_BIN="$test_dir/bin/az" \
  CURL_BIN="$test_dir/bin/curl" \
  FLEET_DEPLOY_CONTAINER_HELPER="$test_dir/fleet-deploy" \
  LIVE_DURABILITY_CHECKER="$test_dir/live-checker" \
  LIVE_TOPOLOGY_CHECKER="$repo_root/scripts/verify-live-topology.sh" \
  DEPLOY_VERIFY_ATTEMPTS=1 \
  "$script" accessible-explanation-checkin "$repo_root" Dockerfile 8080)

jq -e '
  .properties.template.scale == {minReplicas: 1, maxReplicas: 1}
  and .properties.template.volumes == [{
    name: "checkin-data",
    storageType: "AzureFile",
    storageName: "aec-accessible-explanati-9c1a54"
  }]
  and (.properties.template.containers[] | select(.name == "app") | .volumeMounts) == [{
    volumeName: "checkin-data",
    mountPath: "/app/data"
  }]
' "$test_dir/patch.json" >/dev/null

grep -Fxq "accessible-explanation-checkin $repo_root Dockerfile 8080" "$test_dir/fleet-args"
grep -Eq "^https://accessible-explanation-checkin.sociobot.in sf-accessible-explanation-9c1a54 sociobot [a-f0-9]{40} aec-accessible-explanati-9c1a54 sf-accessible-explanation-checkin-data$" "$test_dir/live-checker-args"
grep -Fq 'sf-accessible-explanation-9c1a54--0000001' "$test_dir/deactivated"
[[ "$output" == *"PASS: deployed and verified sf-accessible-explanation-9c1a54"* ]]
[[ "$output" == *'"result": "PASS"'* ]]
[[ -f "$test_dir/durability-workflow-finished" ]]

# Reproduce verification 14's exact failure class after the durability
# workflow makes its replacement revision. The public deploy command must not
# accept the initial patch when the final revision permits three SQLite writers.
rm -f "$test_dir/durability-workflow-finished"
if PATH="$test_dir/bin:$PATH" \
  MOCK_STATE_DIR="$test_dir" \
  MOCK_BUILD_SHA="$test_sha" \
  MOCK_REGRESS_AFTER_DURABILITY=1 \
  AZ_BIN="$test_dir/bin/az" \
  CURL_BIN="$test_dir/bin/curl" \
  FLEET_DEPLOY_CONTAINER_HELPER="$test_dir/fleet-deploy" \
  LIVE_DURABILITY_CHECKER="$test_dir/live-checker" \
  LIVE_TOPOLOGY_CHECKER="$repo_root/scripts/verify-live-topology.sh" \
  DEPLOY_VERIFY_ATTEMPTS=1 \
  "$script" accessible-explanation-checkin "$repo_root" Dockerfile 8080 \
  >"$test_dir/post-workflow-regression.out" 2>&1; then
  echo 'deployment helper accepted a 1–3 replica topology after its durability revision' >&2
  exit 1
fi
grep -Fq 'expected minReplicas=maxReplicas=1; observed minReplicas=1 maxReplicas=3' \
  "$test_dir/post-workflow-regression.out"

rm -f "$test_dir/patched"
rm -f "$test_dir/durability-workflow-finished"
if PATH="$test_dir/bin:$PATH" \
  MOCK_STATE_DIR="$test_dir" \
  MOCK_APPLY_PATCH=0 \
  MOCK_BUILD_SHA="$test_sha" \
  AZ_BIN="$test_dir/bin/az" \
  CURL_BIN="$test_dir/bin/curl" \
  FLEET_DEPLOY_CONTAINER_HELPER="$test_dir/fleet-deploy" \
  LIVE_DURABILITY_CHECKER="$test_dir/live-checker" \
  LIVE_TOPOLOGY_CHECKER="$repo_root/scripts/verify-live-topology.sh" \
  DEPLOY_VERIFY_ATTEMPTS=1 \
  DEPLOY_VERIFY_INTERVAL_SECONDS=0 \
  "$script" accessible-explanation-checkin "$repo_root" Dockerfile 8080 \
  >"$test_dir/nonconverged.out" 2>&1; then
  echo 'deployment helper succeeded without the required durable topology' >&2
  exit 1
fi
grep -Fq 'did not reach a ready revision with one replica and durable /app/data' "$test_dir/nonconverged.out"

echo 'PASS @claim:durable-deployment-policy: executed deployment converges to one Azure File-backed SQLite replica'
