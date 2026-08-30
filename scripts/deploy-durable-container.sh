#!/usr/bin/env bash
# Deploy through the factory helper with the work-order durable-data contract.
# SQLite cannot safely be replicated across independent container filesystems.
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

app_name="sf-$slug"
if [ ${#app_name} -gt 32 ]; then
  app_name="sf-${slug:0:22}-$(printf '%s' "$slug" | sha1sum | cut -c1-6)"
  app_name=${app_name//--/-}
fi
share_name="sf-${slug}-data"

# The helper owns the Azure Files resource and the Container App template. It
# must receive the work order's data_dir on the operation that builds the
# revision; a later side patch can otherwise be overwritten by a generic
# 1–3-replica deployment.
WO_DATA_DIR="$data_dir" "$fleet_deploy_helper" "$slug" "$repo" "$dockerfile" "$port"

effective=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
storage_name=$(jq -er --arg mount "$data_dir" '
  (.properties.template.volumes // []) as $volumes
  | first(.properties.template.containers[]? | select(.name == "app")
      | .volumeMounts[]? | select(.mountPath == $mount)
      | .volumeName as $volume
      | $volumes[]? | select(.name == $volume and .storageType == "AzureFile")
      | .storageName)
' <<<"$effective") || {
  echo "ERROR: $app_name did not deploy an Azure File volume at $data_dir" >&2
  exit 1
}

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
