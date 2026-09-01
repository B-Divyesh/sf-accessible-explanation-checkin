#!/usr/bin/env bash
# Regression coverage for the verifier-15 production failure. The factory
# helper creates the image revision, then this product wrapper attaches the
# already-registered product Azure File share at the work-order's /data mount
# and pins SQLite to one replica. A later generic 1–3 replica deployment must
# be rejected by the final live topology gate.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
script=${1:-scripts/deploy-durable-container.sh}
if [[ "$script" != /* ]]; then
  script="$repo_root/$script"
fi

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/state"

assert_exact_file() {
  local label=$1
  local expected=$2
  local file=$3
  local actual
  actual=$(<"$file")
  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s mismatch\nexpected: %q\nactual:   %q\n' \
      "$label" "$expected" "$actual" >&2
    exit 1
  fi
}

cat > "$test_dir/fleet-deploy" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$MOCK_STATE_DIR/fleet-args"
printf '%s\n' "${WO_DATA_DIR-unset}" > "$MOCK_STATE_DIR/fleet-data-dir"
MOCK

cat > "$test_dir/live-checker" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$MOCK_STATE_DIR/live-checker-args"
# A real durability workflow creates a replacement revision. Mark this point
# so the final real topology checker can reproduce a later regression.
: > "$MOCK_STATE_DIR/durability-workflow-finished"
printf '%s\n' '{"result":"PASS"}'
MOCK

cat > "$test_dir/bin/az" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
args="$*"
case "$args" in
  'containerapp show '*)
    if [[ "${MOCK_REGRESS_AFTER_DURABILITY:-0}" == 1 && -f "$MOCK_STATE_DIR/durability-workflow-finished" ]]; then
      cat "$MOCK_STATE_DIR/regressed-app.json"
    else
      cat "$MOCK_STATE_DIR/app.json"
    fi
    ;;
  'containerapp env storage show '*) cat "$MOCK_STATE_DIR/storage.json" ;;
  'containerapp revision list '*) cat "$MOCK_STATE_DIR/revisions.json" ;;
  'containerapp replica list '*) cat "$MOCK_STATE_DIR/replicas.json" ;;
  'account show '*) printf 'subscription-test\n' ;;
  'rest --method patch '*)
    body=''
    while (($#)); do
      if [[ "$1" == --body ]]; then
        body=$2
        break
      fi
      shift
    done
    printf '%s' "$body" > "$MOCK_STATE_DIR/template-patch.json"
    cp "$MOCK_STATE_DIR/durable-app.json" "$MOCK_STATE_DIR/app.json"
    ;;
  *) echo "unexpected az command: $args" >&2; exit 1 ;;
esac
MOCK

cat > "$test_dir/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '{"build_sha":"%s","status":"ok"}\n' "${MOCK_BUILD_SHA:?}"
MOCK

chmod +x "$test_dir/fleet-deploy" "$test_dir/live-checker" \
  "$test_dir/bin/az" "$test_dir/bin/curl"

test_sha=$(git -C "$repo_root" rev-parse HEAD)
storage_name='aec-accessible-explanati-9c1a54'
share_name='sf-accessible-explanation-checkin-data'

cat > "$test_dir/state/stateless-app.json" <<JSON
{"name":"sf-accessible-explanation-9c1a54","properties":{"configuration":{"ingress":{"customDomains":[{"name":"accessible-explanation-checkin.sociobot.in","bindingType":"SniEnabled"}]}},"latestRevisionName":"sf-accessible-explanation-9c1a54--0000119","latestReadyRevisionName":"sf-accessible-explanation-9c1a54--0000119","template":{"scale":{"minReplicas":1,"maxReplicas":3},"volumes":null,"containers":[{"name":"app","image":"example.invalid/app:${test_sha:0:12}","volumeMounts":null}]}}}
JSON
cat > "$test_dir/state/durable-app.json" <<JSON
{"name":"sf-accessible-explanation-9c1a54","properties":{"configuration":{"ingress":{"customDomains":[{"name":"accessible-explanation-checkin.sociobot.in","bindingType":"SniEnabled"}]}},"latestRevisionName":"sf-accessible-explanation-9c1a54--0000120","latestReadyRevisionName":"sf-accessible-explanation-9c1a54--0000120","template":{"scale":{"minReplicas":1,"maxReplicas":1},"volumes":[{"name":"data","storageType":"AzureFile","storageName":"$storage_name"}],"containers":[{"name":"app","image":"example.invalid/app:${test_sha:0:12}","volumeMounts":[{"volumeName":"data","mountPath":"/data"}]}]}}}
JSON
cat > "$test_dir/state/regressed-app.json" <<JSON
{"name":"sf-accessible-explanation-9c1a54","properties":{"configuration":{"ingress":{"customDomains":[{"name":"accessible-explanation-checkin.sociobot.in","bindingType":"SniEnabled"}]}},"latestRevisionName":"sf-accessible-explanation-9c1a54--0000121","latestReadyRevisionName":"sf-accessible-explanation-9c1a54--0000121","template":{"scale":{"minReplicas":1,"maxReplicas":3},"volumes":[{"name":"data","storageType":"AzureFile","storageName":"$storage_name"}],"containers":[{"name":"app","image":"example.invalid/app:${test_sha:0:12}","volumeMounts":[{"volumeName":"data","mountPath":"/data"}]}]}}}
JSON
cat > "$test_dir/state/storage.json" <<JSON
{"properties":{"azureFile":{"accessMode":"ReadWrite","shareName":"$share_name"}}}
JSON
cat > "$test_dir/state/revisions.json" <<'JSON'
[{"name":"sf-accessible-explanation-9c1a54--0000120","properties":{"active":true,"healthState":"Healthy","provisioningState":"Provisioned","runningState":"Running"}}]
JSON
cat > "$test_dir/state/replicas.json" <<'JSON'
[{"name":"replica-a","properties":{"runningState":"Running","containers":[{"name":"app","ready":true,"started":true,"runningState":"Running"}]}}]
JSON
cp "$test_dir/state/stateless-app.json" "$test_dir/state/app.json"

run_deploy() {
  local deploy_repo=${1:-$repo_root}
  PATH="$test_dir/bin:$PATH" \
    MOCK_STATE_DIR="$test_dir/state" \
    MOCK_BUILD_SHA="$test_sha" \
    AZ_BIN="$test_dir/bin/az" \
    CURL_BIN="$test_dir/bin/curl" \
    FLEET_DEPLOY_CONTAINER_HELPER="$test_dir/fleet-deploy" \
    LIVE_DURABILITY_CHECKER="$test_dir/live-checker" \
    LIVE_TOPOLOGY_CHECKER="$repo_root/scripts/verify-live-topology.sh" \
    npm --prefix "$deploy_repo" run deploy --silent
}

output=$(run_deploy)
assert_exact_file 'default deployment helper arguments' \
  "accessible-explanation-checkin $repo_root Dockerfile 8080" \
  "$test_dir/state/fleet-args"
assert_exact_file 'generic helper durable-path override' '' "$test_dir/state/fleet-data-dir"
grep -Eq "^https://accessible-explanation-checkin.sociobot.in sf-accessible-explanation-9c1a54 sociobot [a-f0-9]{40} $storage_name $share_name$" "$test_dir/state/live-checker-args"
[[ "$output" == *"PASS: deployed and verified sf-accessible-explanation-9c1a54 with durable /data"* ]]
[[ "$output" == *'"result": "PASS"'* ]]
jq -e '
  .properties.template.scale == {minReplicas: 1, maxReplicas: 1}
  and (.properties.template.volumes[] | select(.name == "data" and .storageType == "AzureFile"))
  and (.properties.template.containers[] | select(.name == "app") | .volumeMounts[] | select(.volumeName == "data" and .mountPath == "/data"))
' "$test_dir/state/app.json" >/dev/null
jq -e --arg storage "$storage_name" '
  .properties.template.scale == {minReplicas: 1, maxReplicas: 1}
  and (.properties.template.volumes[] | select(.name == "data" and .storageType == "AzureFile" and .storageName == $storage))
  and (.properties.template.containers[] | select(.name == "app") | .volumeMounts[] | select(.volumeName == "data" and .mountPath == "/data"))
' "$test_dir/state/template-patch.json" >/dev/null

# npm's deploy command does not pass a repository argument. Reproduce the
# verifier-16 clean-clone condition in an actual clone under a different path;
# the wrapper must derive the path from its own scripts/ location.
relocated_repo="$test_dir/clean-clone-outside-workspace"
git clone --quiet --no-local "$repo_root" "$relocated_repo"
# The fixture runs before this repair is committed, so place the script under
# test into the otherwise clean clone. The package command still invokes it
# without positional arguments, exactly as `npm run deploy` does in CI.
cp "$script" "$relocated_repo/scripts/deploy-durable-container.sh"
cp "$test_dir/state/stateless-app.json" "$test_dir/state/app.json"
rm -f "$test_dir/state/durability-workflow-finished"
relocated_output=$(run_deploy "$relocated_repo")
assert_exact_file 'relocated clean-clone helper arguments' \
  "accessible-explanation-checkin $relocated_repo Dockerfile 8080" \
  "$test_dir/state/fleet-args"
[[ "$relocated_output" == *"PASS: deployed and verified sf-accessible-explanation-9c1a54 with durable /data"* ]]

# This is verifier 15's exact failure after the durability workflow creates a
# new revision: maxReplicas regresses from one to three. The final live
# topology check must fail rather than reporting deployment success.
cp "$test_dir/state/stateless-app.json" "$test_dir/state/app.json"
rm -f "$test_dir/state/durability-workflow-finished"
if MOCK_REGRESS_AFTER_DURABILITY=1 run_deploy >"$test_dir/regressed.out" 2>&1; then
  echo 'deployment accepted a one-to-three replica topology after the workflow revision' >&2
  exit 1
fi
grep -Fq 'expected minReplicas=maxReplicas=1; observed minReplicas=1 maxReplicas=3' \
  "$test_dir/regressed.out"

# The wrapper may patch only the Container App template. It must not create or
# access storage credentials: the factory owns the existing product share.
if rg -q 'az storage|storage account keys|env storage set|storage share create' "$script"; then
  echo 'deployment wrapper attempts to manage Azure storage credentials or shares' >&2
  exit 1
fi
rg -Fq 'data_dir=${DEPLOY_DATA_DIR:-/data}' "$script"
rg -Fq 'WO_DATA_DIR= "$fleet_deploy_helper"' "$script"
rg -Fq 'minReplicas: 1, maxReplicas: 1' "$script"

# The factory contract fixes this stateful product's durable path at /data.
# An inherited deployment setting must fail before the generic helper can make
# a stateless revision with a mismatched mount path.
rm -f "$test_dir/state/fleet-args"
if DEPLOY_DATA_DIR=/app/data run_deploy >"$test_dir/wrong-data-dir.out" 2>&1; then
  echo 'deployment accepted a durable path other than the work-order /data mount' >&2
  exit 1
fi
grep -Fq 'requires DEPLOY_DATA_DIR=/data; received /app/data' "$test_dir/wrong-data-dir.out"
test ! -e "$test_dir/state/fleet-args"

echo 'PASS @claim:durable-deployment-policy: registered Azure Files mounts at /data, one replica is patched, and verifier-15 multi-replica state is rejected'
