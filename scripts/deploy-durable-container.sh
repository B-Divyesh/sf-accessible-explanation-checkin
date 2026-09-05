#!/usr/bin/env bash
# Deploy through the factory helper, then apply this work order's /data mount
# to the same revision template. SQLite cannot safely be replicated across
# independent container filesystems.
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
default_repo=$(cd -- "$script_dir/.." && pwd -P)
slug=${1:-accessible-explanation-checkin}
# `npm run deploy` passes no repository argument. Resolve that default from
# this checked-out script, rather than from the factory worker's workspace,
# so a clean clone can be built and deployed from any path.
repo=${2:-$default_repo}
dockerfile=${3:-Dockerfile}
port=${4:-8080}
fleet_deploy_helper=${FLEET_DEPLOY_CONTAINER_HELPER:-/opt/fleet/lib/deploy-container.sh}
live_durability_checker=${LIVE_DURABILITY_CHECKER:-$repo/scripts/verify-live-durable-workflow.sh}
live_topology_checker=${LIVE_TOPOLOGY_CHECKER:-$repo/scripts/verify-live-topology.sh}
candidate_resolver=${PRODUCT_CANDIDATE_RESOLVER:-$repo/scripts/resolve-product-candidate.sh}
resource_group=${AZURE_RESOURCE_GROUP:-sociobot}
data_dir=${DEPLOY_DATA_DIR:-/data}
storage_name=${DEPLOY_STORAGE_NAME:-aec-accessible-explanati-9c1a54}
az_bin=${AZ_BIN:-az}

# This service keeps its durable Azure Files contract at /data. Do not allow a
# generic worker setting to silently move the mount: the runtime restores its
# SQLite snapshot and voice uploads from this exact path on every revision.
if [[ "$data_dir" != /data ]]; then
  echo "ERROR: accessible-explanation-checkin requires DEPLOY_DATA_DIR=/data; received $data_dir" >&2
  exit 2
fi

app_name="sf-$slug"
if [ ${#app_name} -gt 32 ]; then
  app_name="sf-${slug:0:22}-$(printf '%s' "$slug" | sha1sum | cut -c1-6)"
  app_name=${app_name//--/-}
fi
share_name="sf-${slug}-data"

# Build the last shipped product commit, not a newer report or Graphify commit.
# The factory helper derives both the image tag and Docker BUILD_SHA from the
# checkout HEAD, so give it a clean detached checkout at that exact candidate.
expected_build_sha=$("$candidate_resolver" "$repo")
if [[ ! "$expected_build_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR: product candidate resolver returned an invalid SHA: $expected_build_sha" >&2
  exit 2
fi
build_root=$(mktemp -d)
cleanup() {
  if [[ -n "${build_root:-}" && -d "$build_root" ]]; then
    rm -rf -- "$build_root"
  fi
}
trap cleanup EXIT
build_repo="$build_root/source"
git clone --quiet --no-local --no-checkout "$repo" "$build_repo"
git -C "$build_repo" checkout --quiet --detach "$expected_build_sha"
actual_build_sha=$(git -C "$build_repo" rev-parse HEAD)
if [[ "$actual_build_sha" != "$expected_build_sha" ]] || \
  [[ -n "$(git -C "$build_repo" status --porcelain --untracked-files=no)" ]]; then
  echo "ERROR: could not prepare a clean product candidate checkout at $expected_build_sha" >&2
  exit 2
fi
echo "== product candidate $expected_build_sha"

# The factory helper builds the image and keeps the app's ingress, identity and
# secrets. Its automatic Azure-storage resource name exceeds this product's
# environment-storage limit, so reuse the product share already registered by
# the factory and patch only the revision template. This wrapper never creates
# a share, account key, or environment storage resource.
# The factory environment also exports WO_DATA_DIR. Do not let the generic
# helper attempt to register its overlong derived storage name before this
# wrapper attaches the existing, valid environment-storage resource below.
WO_DATA_DIR= "$fleet_deploy_helper" "$slug" "$build_repo" "$dockerfile" "$port"

app=$($az_bin containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
template=$(jq --arg storage "$storage_name" --arg mount "$data_dir" '
  .properties.template
  | .scale = {minReplicas: 1, maxReplicas: 1}
  | .volumes = ((.volumes // [] | map(select(.name != "data")))
      + [{name: "data", storageType: "AzureFile", storageName: $storage}])
  | .containers |= map(if .name == "app" then
      .volumeMounts = ((.volumeMounts // [] | map(select(.mountPath != $mount)))
        + [{volumeName: "data", mountPath: $mount}])
    else . end)
' <<<"$app")
payload=$(jq -n --argjson template "$template" '{properties:{template:$template}}')
subscription=$($az_bin account show --query id --output tsv)
$az_bin rest --method patch \
  --url "https://management.azure.com/subscriptions/$subscription/resourceGroups/$resource_group/providers/Microsoft.App/containerApps/$app_name?api-version=2024-03-01" \
  --body "$payload" --output none

# The helper waits for ARM provisioning, but a newly created revision can take
# a little longer to become the sole healthy replica. Do not create a private
# test record until the read-only live topology gate confirms the ready /data
# deployment.
topology_ready=false
for _ in $(seq 1 "${DEPLOY_VERIFY_ATTEMPTS:-30}"); do
  if "$live_topology_checker" \
    "https://$slug.sociobot.in" \
    "$app_name" \
    "$resource_group" \
    "$expected_build_sha" \
    "$storage_name" \
    "$share_name" >/dev/null 2>&1; then
    topology_ready=true
    break
  fi
  sleep "${DEPLOY_VERIFY_INTERVAL_SECONDS:-10}"
done
if [[ "$topology_ready" != true ]]; then
  echo "ERROR: $app_name did not become a ready one-replica /data deployment" >&2
  exit 1
fi

"$live_durability_checker" \
  "https://$slug.sociobot.in" \
  "$app_name" \
  "$resource_group" \
  "$expected_build_sha" \
  "$storage_name" \
  "$share_name"

# Re-read production after the replacement-revision workflow. This is the
# release check that catches a generic deployment overwriting the mount or
# replica limits; it intentionally uses real control-plane state.
"$live_topology_checker" \
  "https://$slug.sociobot.in" \
  "$app_name" \
  "$resource_group" \
  "$expected_build_sha" \
  "$storage_name" \
  "$share_name"

echo "PASS: deployed and verified $app_name with durable $data_dir, exactly one SQLite replica, and new-revision persistence"
