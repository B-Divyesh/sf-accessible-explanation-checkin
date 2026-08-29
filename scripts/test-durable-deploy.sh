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
  : > "$MOCK_STATE_DIR/patched"
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

chmod +x "$test_dir/fleet-deploy" "$test_dir/bin/az"

cat > "$test_dir/stateless-app.json" <<'JSON'
{"properties":{"template":{"scale":{"minReplicas":1,"maxReplicas":3},"volumes":null,"containers":[{"name":"app","image":"example.invalid/app:before"}]}}}
JSON

cat > "$test_dir/patched-app.json" <<'JSON'
{"properties":{"template":{"scale":{"minReplicas":1,"maxReplicas":1},"volumes":[{"name":"checkin-data","storageType":"AzureFile","storageName":"aec-accessible-explanati-9c1a54"}],"containers":[{"name":"app","image":"example.invalid/app:after","volumeMounts":[{"volumeName":"checkin-data","mountPath":"/app/data"}]}]}}}
JSON

output=$(PATH="$test_dir/bin:$PATH" \
  MOCK_STATE_DIR="$test_dir" \
  FLEET_DEPLOY_CONTAINER_HELPER="$test_dir/fleet-deploy" \
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
[[ "$output" == *"PASS: deployed and verified sf-accessible-explanation-9c1a54"* ]]

echo 'PASS @claim:durable-deployment-policy: executed deployment converges to one Azure File-backed SQLite replica'
