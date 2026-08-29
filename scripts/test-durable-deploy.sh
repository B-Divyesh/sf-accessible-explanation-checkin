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
echo '{"result":"PASS"}'
MOCK

cat > "$test_dir/topology-checker" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$MOCK_STATE_DIR/topology-checker-args"
echo '{"result":"PASS"}'
MOCK

cat > "$test_dir/bin/az" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
args="$*"

if [[ "$args" == "storage account keys list"* ]]; then
  printf '%s\n' 'mock-storage-key'
elif [[ "$args" == "storage share create"* || "$args" == "containerapp env storage set"* ]]; then
  exit 0
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
  if [[ -f "$MOCK_STATE_DIR/patched" ]]; then
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
  "$test_dir/topology-checker" "$test_dir/bin/az"

cat > "$test_dir/stateless-app.json" <<'JSON'
{"properties":{"latestRevisionName":"sf-accessible-explanation-9c1a54--0000001","latestReadyRevisionName":"sf-accessible-explanation-9c1a54--0000001","template":{"scale":{"minReplicas":1,"maxReplicas":3},"volumes":null,"containers":[{"name":"app","image":"example.invalid/app:before"}]}}}
JSON

cat > "$test_dir/patched-app.json" <<'JSON'
{"properties":{"latestRevisionName":"sf-accessible-explanation-9c1a54--0000002","latestReadyRevisionName":"sf-accessible-explanation-9c1a54--0000002","template":{"scale":{"minReplicas":1,"maxReplicas":1},"volumes":[{"name":"checkin-data","storageType":"AzureFile","storageName":"aec-accessible-explanati-9c1a54"}],"containers":[{"name":"app","image":"example.invalid/app:after","volumeMounts":[{"volumeName":"checkin-data","mountPath":"/app/data"}]}]}}}
JSON

# The factory's generic Container Apps helper deliberately creates a stateless
# 1–3 replica template. The public deployment command must therefore run the
# durable wrapper, rather than exposing that helper as this product's deploy
# entry point. Execute the actual package command against that unsafe fixture.
package_output=$(cd "$repo_root" && \
  PATH="$test_dir/bin:$PATH" \
  MOCK_STATE_DIR="$test_dir" \
  FLEET_DEPLOY_CONTAINER_HELPER="$test_dir/fleet-deploy" \
  LIVE_DURABILITY_CHECKER="$test_dir/live-checker" \
  LIVE_TOPOLOGY_CHECKER="$test_dir/topology-checker" \
  DEPLOY_VERIFY_ATTEMPTS=1 \
  npm run deploy --silent)

jq -e '
  .properties.template.scale == {minReplicas: 1, maxReplicas: 1}
  and (.properties.template.volumes[] | select(.name == "checkin-data") | .storageType) == "AzureFile"
  and (.properties.template.containers[] | select(.name == "app") | .volumeMounts[] | select(.mountPath == "/app/data") | .volumeName) == "checkin-data"
' "$test_dir/patch.json" >/dev/null
[[ "$package_output" == *"PASS: deployed and verified sf-accessible-explanation-9c1a54"* ]]

output=$(PATH="$test_dir/bin:$PATH" \
  MOCK_STATE_DIR="$test_dir" \
  FLEET_DEPLOY_CONTAINER_HELPER="$test_dir/fleet-deploy" \
  LIVE_DURABILITY_CHECKER="$test_dir/live-checker" \
  LIVE_TOPOLOGY_CHECKER="$test_dir/topology-checker" \
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
grep -Eq "^https://accessible-explanation-checkin.sociobot.in sf-accessible-explanation-9c1a54 sociobot [a-f0-9]{40} aec-accessible-explanati-9c1a54 sf-accessible-explanation-checkin-data$" "$test_dir/topology-checker-args"
grep -Fq 'sf-accessible-explanation-9c1a54--0000001' "$test_dir/deactivated"
[[ "$output" == *"PASS: deployed and verified sf-accessible-explanation-9c1a54"* ]]

rm -f "$test_dir/patched"
if PATH="$test_dir/bin:$PATH" \
  MOCK_STATE_DIR="$test_dir" \
  MOCK_APPLY_PATCH=0 \
  FLEET_DEPLOY_CONTAINER_HELPER="$test_dir/fleet-deploy" \
  LIVE_DURABILITY_CHECKER="$test_dir/live-checker" \
  LIVE_TOPOLOGY_CHECKER="$test_dir/topology-checker" \
  DEPLOY_VERIFY_ATTEMPTS=1 \
  DEPLOY_VERIFY_INTERVAL_SECONDS=0 \
  "$script" accessible-explanation-checkin "$repo_root" Dockerfile 8080 \
  >"$test_dir/nonconverged.out" 2>&1; then
  echo 'deployment helper succeeded without the required durable topology' >&2
  exit 1
fi
grep -Fq 'did not reach a ready revision with one replica and durable /app/data' "$test_dir/nonconverged.out"

echo 'PASS @claim:durable-deployment-policy: executed deployment converges to one Azure File-backed SQLite replica'
