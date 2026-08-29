#!/usr/bin/env bash
# Read-only release gate for the production SQLite topology. Unlike the
# deployment fixtures, this script queries the effective Azure control plane
# and the live /health endpoint.
set -euo pipefail

base_url=${1:-https://accessible-explanation-checkin.sociobot.in}
app_name=${2:-sf-accessible-explanation-9c1a54}
resource_group=${3:-sociobot}
expected_build_sha=${4:-}
expected_storage_name=${5:-}
expected_share_name=${6:-}
environment=${AZURE_CONTAINERAPP_ENV:-factory-env}
az_bin=${AZ_BIN:-az}
curl_bin=${CURL_BIN:-curl}

fail() {
  echo "ERROR: live topology check failed: $*" >&2
  exit 1
}

topology=$($az_bin containerapp show --resource-group "$resource_group" \
  --name "$app_name" --output json)
revision=$(jq -er '.properties.latestRevisionName' <<<"$topology")
ready_revision=$(jq -er '.properties.latestReadyRevisionName' <<<"$topology")
[[ "$revision" == "$ready_revision" ]] || \
  fail "latest revision $revision is not the ready revision $ready_revision"

min_replicas=$(jq -er '.properties.template.scale.minReplicas' <<<"$topology")
max_replicas=$(jq -er '.properties.template.scale.maxReplicas' <<<"$topology")
[[ "$min_replicas" == 1 && "$max_replicas" == 1 ]] || \
  fail "expected minReplicas=maxReplicas=1; observed minReplicas=$min_replicas maxReplicas=$max_replicas"

if ! jq -e --arg storage "$expected_storage_name" '
  any(.properties.template.volumes[]?;
    .name == "checkin-data"
    and .storageType == "AzureFile"
    and ($storage == "" or .storageName == $storage))
  and any(.properties.template.containers[]?;
    .name == "app"
    and any(.volumeMounts[]?;
      .volumeName == "checkin-data" and .mountPath == "/app/data"))
' >/dev/null <<<"$topology"; then
  fail "expected the checkin-data Azure File volume mounted at /app/data"
fi

image=$(jq -er '.properties.template.containers[] | select(.name == "app") | .image' \
  <<<"$topology")
if [[ -n "$expected_build_sha" && "$image" != *":${expected_build_sha:0:12}" ]]; then
  fail "image $image does not identify build ${expected_build_sha:0:12}"
fi

if [[ -n "$expected_storage_name" && -n "$expected_share_name" ]]; then
  storage=$($az_bin containerapp env storage show --resource-group "$resource_group" \
    --name "$environment" --storage-name "$expected_storage_name" --output json)
  if ! jq -e --arg share "$expected_share_name" '
    .properties.azureFile.accessMode == "ReadWrite"
    and .properties.azureFile.shareName == $share
  ' >/dev/null <<<"$storage"; then
    fail "storage $expected_storage_name is not the read-write share $expected_share_name"
  fi
fi

revisions=$($az_bin containerapp revision list --resource-group "$resource_group" \
  --name "$app_name" --output json)
active_revisions=$(jq '[.[] | select(.properties.active == true)] | length' <<<"$revisions")
[[ "$active_revisions" == 1 ]] || \
  fail "expected one active revision; observed $active_revisions"
if ! jq -e --arg revision "$revision" '
  any(.[];
    .name == $revision
    and .properties.active == true
    and .properties.healthState == "Healthy"
    and .properties.provisioningState == "Provisioned"
    and (.properties.runningState | startswith("Running")))
' >/dev/null <<<"$revisions"; then
  fail "ready revision $revision is not the sole active, healthy, running revision"
fi
revision_health=$(jq -er --arg revision "$revision" \
  '.[] | select(.name == $revision) | .properties.healthState' <<<"$revisions")
revision_state=$(jq -er --arg revision "$revision" \
  '.[] | select(.name == $revision) | .properties.runningState' <<<"$revisions")

replicas=$($az_bin containerapp replica list --resource-group "$resource_group" \
  --name "$app_name" --revision "$revision" --output json)
running_replicas=$(jq '[.[] | select(.properties.runningState == "Running")] | length' \
  <<<"$replicas")
[[ "$running_replicas" == 1 ]] || \
  fail "expected one running replica; observed $running_replicas"
ready_replicas=$(jq '[.[] | select(
  .properties.runningState == "Running"
  and any(.properties.containers[]?;
    .name == "app"
    and .ready == true
    and .started == true
    and .runningState == "Running"))] | length' <<<"$replicas")
[[ "$ready_replicas" == 1 ]] || \
  fail "expected one ready app replica; observed $ready_replicas"

health=$($curl_bin --fail --silent --show-error --no-keepalive \
  --header 'Cache-Control: no-cache' "$base_url/health")
health_sha=$(jq -er '.build_sha' <<<"$health")
[[ -z "$expected_build_sha" || "$health_sha" == "$expected_build_sha" ]] || \
  fail "live /health identifies $health_sha instead of $expected_build_sha"

jq -n \
  --arg base_url "$base_url" \
  --arg app "$app_name" \
  --arg revision "$revision" \
  --arg image "$image" \
  --arg build_sha "$health_sha" \
  --arg storage_name "$expected_storage_name" \
  --arg share_name "$expected_share_name" \
  --arg revision_health "$revision_health" \
  --arg revision_state "$revision_state" \
  '{
    result: "PASS",
    base_url: $base_url,
    container_app: $app,
    revision: $revision,
    image: $image,
    build_sha: $build_sha,
    topology: {
      min_replicas: 1,
      max_replicas: 1,
      active_revisions: 1,
      running_replicas: 1,
      ready_replicas: 1,
      revision_health: $revision_health,
      revision_state: $revision_state,
      volume: "checkin-data",
      mount_path: "/app/data",
      storage_name: $storage_name,
      share_name: $share_name
    }
  }'
