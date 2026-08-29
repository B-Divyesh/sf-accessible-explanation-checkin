#!/usr/bin/env bash
# Prove that the deployed SQLite service has one durable replica and that its
# central private-link workflow survives replacement by a new production
# revision.
set -euo pipefail

base_url=${1:-https://accessible-explanation-checkin.sociobot.in}
app_name=${2:-sf-accessible-explanation-9c1a54}
resource_group=${3:-sociobot}
expected_build_sha=${4:-}
expected_storage_name=${5:-}
expected_share_name=${6:-}
read_attempts=${DURABILITY_READ_ATTEMPTS:-24}
revision_attempts=${DURABILITY_REVISION_ATTEMPTS:-${DURABILITY_RESTART_ATTEMPTS:-36}}
revision_interval=${DURABILITY_REVISION_INTERVAL_SECONDS:-${DURABILITY_RESTART_INTERVAL_SECONDS:-5}}
curl_bin=${CURL_BIN:-curl}
az_bin=${AZ_BIN:-az}
test_client_ip=${DURABILITY_CLIENT_IP:-192.0.2.44}
environment=${AZURE_CONTAINERAPP_ENV:-factory-env}

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
body_file="$test_dir/body.json"

fail() {
  echo "ERROR: live durability check failed: $*" >&2
  exit 1
}

request() {
  local method=$1
  local url=$2
  local data=${3:-}
  local args=(--silent --show-error --output "$body_file" --write-out '%{http_code}'
    --no-keepalive --header 'Connection: close'
    --header "X-Forwarded-For: $test_client_ip" --request "$method")
  if [[ -n "$data" ]]; then
    args+=(--header 'Content-Type: application/json' --data "$data")
  fi
  "$curl_bin" "${args[@]}" "$url"
}

expect_status() {
  local expected=$1
  local actual=$2
  local label=$3
  if [[ "$actual" != "$expected" ]]; then
    fail "$label returned $actual, expected $expected; body=$(tr '\n' ' ' < "$body_file")"
  fi
}

topology=$($az_bin containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
if ! jq -e --arg storage "$expected_storage_name" '
  .properties.latestRevisionName == .properties.latestReadyRevisionName
  and .properties.template.scale.minReplicas == 1
  and .properties.template.scale.maxReplicas == 1
  and any(.properties.template.volumes[]?;
    .name == "checkin-data"
    and .storageType == "AzureFile"
    and ($storage == "" or .storageName == $storage))
  and any(.properties.template.containers[]?;
    .name == "app"
    and any(.volumeMounts[]?;
      .volumeName == "checkin-data" and .mountPath == "/app/data"))
' >/dev/null <<<"$topology"; then
  fail "Azure control plane does not show the ready one-replica Azure Files topology"
fi
original_revision=$(jq -r '.properties.latestRevisionName' <<<"$topology")
if [[ -n "$expected_storage_name" && -n "$expected_share_name" ]]; then
  storage=$($az_bin containerapp env storage show --resource-group "$resource_group" \
    --name "$environment" --storage-name "$expected_storage_name" --output json)
  if ! jq -e --arg share "$expected_share_name" '
    .properties.azureFile.accessMode == "ReadWrite"
    and .properties.azureFile.shareName == $share
  ' >/dev/null <<<"$storage"; then
    fail "environment storage $expected_storage_name is not the expected read-write Azure File share $expected_share_name"
  fi
fi

active_revisions=$($az_bin containerapp revision list --resource-group "$resource_group" \
  --name "$app_name" --output json)
if ! jq -e --arg revision "$original_revision" '
  ([.[] | select(.properties.active == true)] | length) == 1
  and any(.[]; .name == $revision and .properties.active == true)
' >/dev/null <<<"$active_revisions"; then
  fail "Azure control plane does not show exactly one active revision before the durability check"
fi
replicas=$($az_bin containerapp replica list --resource-group "$resource_group" \
  --name "$app_name" --revision "$original_revision" --output json)
running=$(jq '[.[] | select(.properties.runningState == "Running")] | length' <<<"$replicas")
[[ "$running" == 1 ]] || fail "revision $original_revision has $running running replicas, expected 1"
original_replica=$(jq -er '.[] | select(.properties.runningState == "Running") | .name' <<<"$replicas")

marker="durability-$(date -u +%Y%m%dT%H%M%SZ)-$$"
create_payload=$(jq -nc --arg marker "$marker" '{
  title: ("Deployment restart check " + $marker),
  prompt: "Which example changed your conclusion, and why?",
  voice_retention_days: 3
}')
status=$(request POST "$base_url/api/checkins" "$create_payload")
expect_status 201 "$status" 'create check-in'
student_token=$(jq -er '.student_token' "$body_file")
review_token=$(jq -er '.review_token' "$body_file")

read_private_links() {
  local phase=$1
  local status
  for i in $(seq 1 "$read_attempts"); do
    status=$(request GET "$base_url/api/checkins/$student_token")
    expect_status 200 "$status" "$phase student-link read $i/$read_attempts"
    status=$(request GET "$base_url/api/reviews/$review_token")
    expect_status 200 "$status" "$phase review-link read $i/$read_attempts"
  done
}

read_receipt() {
  local phase=$1
  local status
  for i in $(seq 1 "$read_attempts"); do
    status=$(request GET "$base_url/api/receipts/$receipt_token")
    expect_status 200 "$status" "$phase receipt read $i/$read_attempts"
  done
}

read_private_links before-restart

submission_payload=$(jq -nc --arg marker "$marker" '{
  student_name: "Deployment verifier",
  explanation_text: ("I compared both examples before choosing the second result. " + $marker),
  confidence: 4
}')
status=$(request POST "$base_url/api/checkins/$student_token/submissions" "$submission_payload")
expect_status 201 "$status" 'student submission'
receipt_token=$(jq -er '.receipt_token' "$body_file")

status=$(request GET "$base_url/api/reviews/$review_token")
expect_status 200 "$status" 'teacher review after submission'
submission_id=$(jq -er --arg marker "$marker" '
  .submissions[] | select(.student_name == "Deployment verifier" and (.explanation_text | contains($marker))) | .id
' "$body_file")
review_payload=$(jq -nc --arg marker "$marker" '{
  teacher_tags: ["Clear reasoning"],
  teacher_note: ("Revision persistence verified for " + $marker),
  follow_up: true
}')
status=$(request PATCH "$base_url/api/reviews/$review_token/submissions/$submission_id" "$review_payload")
expect_status 200 "$status" 'save teacher review'
read_receipt before-restart

$az_bin containerapp update --resource-group "$resource_group" \
  --name "$app_name" --set-env-vars "DURABILITY_REVISION_MARKER=$marker" --output none

revised=false
stable_observations=0
replacement_revision=''
replacement_replica=''
for _ in $(seq 1 "$revision_attempts"); do
  topology=$($az_bin containerapp show --resource-group "$resource_group" \
    --name "$app_name" --output json 2>/dev/null || printf '{}')
  replacement_revision=$(jq -r '.properties.latestRevisionName // empty' <<<"$topology")
  active_revisions=$($az_bin containerapp revision list --resource-group "$resource_group" \
    --name "$app_name" --output json 2>/dev/null || printf '[]')
  active_ready=$(jq -r --arg revision "$replacement_revision" '
    ([.[] | select(.properties.active == true)] | length) == 1
    and any(.[]; .name == $revision and .properties.active == true)
  ' <<<"$active_revisions")
  replicas=$($az_bin containerapp replica list --resource-group "$resource_group" \
    --name "$app_name" --revision "$replacement_revision" --output json 2>/dev/null || printf '[]')
  running=$(jq '[.[] | select(.properties.runningState == "Running")] | length' <<<"$replicas")
  replacement_replica=$(jq -r '[.[] | select(.properties.runningState == "Running") | .name][0] // empty' <<<"$replicas")
  status=$(request GET "$base_url/health" || true)
  topology_ready=$(jq -r --arg original "$original_revision" --arg storage "$expected_storage_name" '
    (.properties.latestRevisionName != $original)
    and (.properties.latestRevisionName == .properties.latestReadyRevisionName)
    and (.properties.template.scale.minReplicas == 1)
    and (.properties.template.scale.maxReplicas == 1)
    and any(.properties.template.volumes[]?;
      .name == "checkin-data"
      and .storageType == "AzureFile"
      and ($storage == "" or .storageName == $storage))
    and any(.properties.template.containers[]?;
      .name == "app"
      and any(.volumeMounts[]?;
        .volumeName == "checkin-data"
        and .mountPath == "/app/data"))
  ' <<<"$topology")
  if [[ "$topology_ready" == true && "$active_ready" == true && "$running" == 1 && -n "$replacement_replica" && "$replacement_replica" != "$original_replica" && "$status" == 200 ]]; then
    health_sha=$(jq -r '.build_sha // empty' "$body_file")
    if [[ -z "$expected_build_sha" || "$health_sha" == "$expected_build_sha" ]]; then
      stable_observations=$((stable_observations + 1))
      if [[ "$stable_observations" -ge 2 ]]; then
        revised=true
        break
      fi
    else
      stable_observations=0
    fi
  else
    stable_observations=0
  fi
  sleep "$revision_interval"
done
[[ "$revised" == true ]] || fail "revision $original_revision did not advance to a distinct ready revision and stabilize at one healthy replacement replica with build $expected_build_sha"

active_revisions=$($az_bin containerapp revision list --resource-group "$resource_group" \
  --name "$app_name" --output json)
if ! jq -e --arg revision "$replacement_revision" '
  ([.[] | select(.properties.active == true)] | length) == 1
  and any(.[]; .name == $revision and .properties.active == true)
' >/dev/null <<<"$active_revisions"; then
  fail "Azure control plane does not show exactly the replacement revision active"
fi

read_private_links after-new-revision
status=$(request GET "$base_url/api/reviews/$review_token")
expect_status 200 "$status" 'teacher review after new revision'
jq -e --arg marker "$marker" '
  any(.submissions[];
    .student_name == "Deployment verifier"
    and (.explanation_text | contains($marker))
    and .confidence == 4
    and .teacher_tags == ["Clear reasoning"]
    and .teacher_note == ("Revision persistence verified for " + $marker)
    and .follow_up == true)
' >/dev/null "$body_file" || fail "submitted explanation or saved teacher review did not persist across the new revision"
read_receipt after-new-revision
jq -e --arg marker "$marker" '
  .student_name == "Deployment verifier"
  and (.explanation_text | contains($marker))
  and .confidence == 4
' >/dev/null "$body_file" || fail "student receipt did not persist across the new revision"

jq -n \
  --arg base "$base_url" \
  --arg app "$app_name" \
  --arg previous_revision "$original_revision" \
  --arg revision "$replacement_revision" \
  --arg build_sha "$expected_build_sha" \
  --arg storage_name "$expected_storage_name" \
  --arg share_name "$expected_share_name" \
  --arg marker "$marker" \
  --argjson reads "$read_attempts" \
  '{
    result: "PASS",
    base_url: $base,
    container_app: $app,
    previous_revision: $previous_revision,
    revision: $revision,
    build_sha: $build_sha,
    marker: $marker,
    topology: {min_replicas: 1, max_replicas: 1, azure_files_mount: "/app/data", storage_name: $storage_name, share_name: $share_name, active_revisions: 1, running_replicas: 1},
    before_new_revision: {student_reads_200: $reads, review_reads_200: $reads, receipt_reads_200: $reads, submission_status: 201, review_saved: true},
    after_new_revision: {student_reads_200: $reads, review_reads_200: $reads, receipt_reads_200: $reads, submission_and_review_persisted: true}
  }'
