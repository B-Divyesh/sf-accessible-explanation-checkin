#!/usr/bin/env bash
# Deploy through the factory helper, then apply this work order's /data mount
# to the same revision template. SQLite cannot safely be replicated across
# independent container filesystems.
set -euo pipefail

slug=${1:-accessible-explanation-checkin}
repo=${2:-/work/repo}
dockerfile=${3:-Dockerfile}
port=${4:-8080}
fleet_deploy_helper=${FLEET_DEPLOY_CONTAINER_HELPER:-/opt/fleet/lib/deploy-container.sh}
live_durability_checker=${LIVE_DURABILITY_CHECKER:-$repo/scripts/verify-live-durable-workflow.sh}
live_topology_checker=${LIVE_TOPOLOGY_CHECKER:-$repo/scripts/verify-live-topology.sh}
resource_group=${AZURE_RESOURCE_GROUP:-sociobot}
data_dir=${DEPLOY_DATA_DIR:-/data}
storage_name=${DEPLOY_STORAGE_NAME:-aec-accessible-explanati-9c1a54}
az_bin=${AZ_BIN:-az}

app_name="sf-$slug"
if [ ${#app_name} -gt 32 ]; then
  app_name="sf-${slug:0:22}-$(printf '%s' "$slug" | sha1sum | cut -c1-6)"
  app_name=${app_name//--/-}
fi
share_name="sf-${slug}-data"

# The factory helper builds the image and keeps the app's ingress, identity and
# secrets. Its automatic Azure-storage resource name exceeds this product's
# environment-storage limit, so reuse the product share already registered by
# the factory and patch only the revision template. This wrapper never creates
# a share, account key, or environment storage resource.
# The factory environment also exports WO_DATA_DIR. Do not let the generic
# helper attempt to register its overlong derived storage name before this
# wrapper attaches the existing, valid environment-storage resource below.
WO_DATA_DIR= "$fleet_deploy_helper" "$slug" "$repo" "$dockerfile" "$port"

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

expected_build_sha=$(git -C "$repo" rev-parse HEAD)

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
