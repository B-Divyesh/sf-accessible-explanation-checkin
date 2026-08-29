#!/usr/bin/env bash
# Prove that the deployed SQLite service has one durable replica and that its
# central private-link workflow survives a restart of the actual revision.
set -euo pipefail

base_url=${1:-https://accessible-explanation-checkin.sociobot.in}
app_name=${2:-sf-accessible-explanation-9c1a54}
resource_group=${3:-sociobot}
expected_build_sha=${4:-}
read_attempts=${DURABILITY_READ_ATTEMPTS:-12}
restart_attempts=${DURABILITY_RESTART_ATTEMPTS:-36}
restart_interval=${DURABILITY_RESTART_INTERVAL_SECONDS:-5}
curl_bin=${CURL_BIN:-curl}
az_bin=${AZ_BIN:-az}
test_client_ip=${DURABILITY_CLIENT_IP:-192.0.2.44}

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
if ! jq -e '
  .properties.latestRevisionName == .properties.latestReadyRevisionName
  and .properties.template.scale.minReplicas == 1
  and .properties.template.scale.maxReplicas == 1
  and any(.properties.template.volumes[]?;
    .name == "checkin-data" and .storageType == "AzureFile")
  and any(.properties.template.containers[]?;
    .name == "app"
    and any(.volumeMounts[]?;
      .volumeName == "checkin-data" and .mountPath == "/app/data"))
' >/dev/null <<<"$topology"; then
  fail "Azure control plane does not show the ready one-replica Azure Files topology"
fi
revision=$(jq -r '.properties.latestRevisionName' <<<"$topology")
replicas=$($az_bin containerapp replica list --resource-group "$resource_group" \
  --name "$app_name" --revision "$revision" --output json)
running=$(jq '[.[] | select(.properties.runningState == "Running")] | length' <<<"$replicas")
[[ "$running" == 1 ]] || fail "revision $revision has $running running replicas, expected 1"
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
  teacher_note: ("Restart persistence verified for " + $marker),
  follow_up: true
}')
status=$(request PATCH "$base_url/api/reviews/$review_token/submissions/$submission_id" "$review_payload")
expect_status 200 "$status" 'save teacher review'

$az_bin containerapp revision restart --resource-group "$resource_group" \
  --name "$app_name" --revision "$revision" --output none

restarted=false
stable_observations=0
for _ in $(seq 1 "$restart_attempts"); do
  replicas=$($az_bin containerapp replica list --resource-group "$resource_group" \
    --name "$app_name" --revision "$revision" --output json 2>/dev/null || printf '[]')
  running=$(jq '[.[] | select(.properties.runningState == "Running")] | length' <<<"$replicas")
  replacement_replica=$(jq -r '[.[] | select(.properties.runningState == "Running") | .name][0] // empty' <<<"$replicas")
  status=$(request GET "$base_url/health" || true)
  if [[ "$running" == 1 && -n "$replacement_replica" && "$replacement_replica" != "$original_replica" && "$status" == 200 ]]; then
    health_sha=$(jq -r '.build_sha // empty' "$body_file")
    if [[ -z "$expected_build_sha" || "$health_sha" == "$expected_build_sha" ]]; then
      stable_observations=$((stable_observations + 1))
      if [[ "$stable_observations" -ge 2 ]]; then
        restarted=true
        break
      fi
    else
      stable_observations=0
    fi
  else
    stable_observations=0
  fi
  sleep "$restart_interval"
done
[[ "$restarted" == true ]] || fail "revision $revision did not replace $original_replica and stabilize at one healthy replica with build $expected_build_sha"

read_private_links after-restart
status=$(request GET "$base_url/api/reviews/$review_token")
expect_status 200 "$status" 'teacher review after restart'
jq -e --arg marker "$marker" '
  any(.submissions[];
    .student_name == "Deployment verifier"
    and (.explanation_text | contains($marker))
    and .confidence == 4
    and .teacher_tags == ["Clear reasoning"]
    and .teacher_note == ("Restart persistence verified for " + $marker)
    and .follow_up == true)
' >/dev/null "$body_file" || fail "submitted explanation or saved teacher review did not persist"
status=$(request GET "$base_url/api/receipts/$receipt_token")
expect_status 200 "$status" 'student receipt after restart'
jq -e --arg marker "$marker" '
  .student_name == "Deployment verifier"
  and (.explanation_text | contains($marker))
  and .confidence == 4
' >/dev/null "$body_file" || fail "student receipt did not persist"

jq -n \
  --arg base "$base_url" \
  --arg app "$app_name" \
  --arg revision "$revision" \
  --arg build_sha "$expected_build_sha" \
  --arg marker "$marker" \
  --argjson reads "$read_attempts" \
  '{
    result: "PASS",
    base_url: $base,
    container_app: $app,
    revision: $revision,
    build_sha: $build_sha,
    marker: $marker,
    topology: {min_replicas: 1, max_replicas: 1, azure_files_mount: "/app/data", running_replicas: 1},
    before_restart: {student_reads_200: $reads, review_reads_200: $reads, submission_status: 201, review_saved: true},
    after_revision_restart: {student_reads_200: $reads, review_reads_200: $reads, receipt_status: 200, submission_and_review_persisted: true}
  }'
