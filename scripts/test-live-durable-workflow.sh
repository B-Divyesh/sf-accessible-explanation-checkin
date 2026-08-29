#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
checker="$repo_root/scripts/verify-live-durable-workflow.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/state"

cat > "$test_dir/bin/az" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
args="$*"
printf '%s\n' "$args" >> "$MOCK_STATE_DIR/az.log"
if [[ "$args" == "containerapp show"* ]]; then
  if [[ -f "$MOCK_STATE_DIR/revised" ]]; then
    revision='app--0000041'
  else
    revision='app--0000040'
  fi
  cat <<JSON
{"properties":{"latestRevisionName":"$revision","latestReadyRevisionName":"$revision","template":{"scale":{"minReplicas":1,"maxReplicas":1},"volumes":[{"name":"checkin-data","storageType":"AzureFile","storageName":"durable"}],"containers":[{"name":"app","volumeMounts":[{"volumeName":"checkin-data","mountPath":"/app/data"}]}]}}}
JSON
elif [[ "$args" == "containerapp env storage show"* ]]; then
  printf '%s\n' '{"properties":{"azureFile":{"accessMode":"ReadWrite","accountName":"storage","shareName":"durable-share"}}}'
elif [[ "$args" == "containerapp revision list"* ]]; then
  if [[ -f "$MOCK_STATE_DIR/revised" ]]; then
    printf '%s\n' '[{"name":"app--0000040","properties":{"active":false}},{"name":"app--0000041","properties":{"active":true}}]'
  else
    printf '%s\n' '[{"name":"app--0000040","properties":{"active":true}}]'
  fi
elif [[ "$args" == "containerapp replica list"* ]]; then
  if [[ -f "$MOCK_STATE_DIR/revised" ]]; then
    printf '%s\n' '[{"name":"app--0000041-new","properties":{"runningState":"Running"}}]'
  else
    printf '%s\n' '[{"name":"app--0000040-old","properties":{"runningState":"Running"}}]'
  fi
elif [[ "$args" == "containerapp update"* ]]; then
  : > "$MOCK_STATE_DIR/revised"
else
  echo "unexpected az command: $args" >&2
  exit 1
fi
MOCK

cat > "$test_dir/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
method=GET
output=''
url=''
while (($#)); do
  case "$1" in
    --request) method=$2; shift 2 ;;
    --output) output=$2; shift 2 ;;
    --header|--data|--write-out) shift 2 ;;
    --silent|--show-error|--no-keepalive) shift ;;
    *) url=$1; shift ;;
  esac
done
printf '%s %s\n' "$method" "$url" >> "$MOCK_STATE_DIR/curl.log"
status=200
body='{}'
case "$method $url" in
  'POST https://example.test/api/checkins')
    status=201; body='{"student_token":"student-token","review_token":"review-token"}' ;;
  'GET https://example.test/api/checkins/student-token')
    if [[ "${MOCK_FAIL_PRIVATE_READ:-0}" == 1 ]]; then
      status=404; body='{"error":"That private link is not valid."}'
    else
      body='{"title":"Deployment restart check","open":true}'
    fi ;;
  'POST https://example.test/api/checkins/student-token/submissions')
    status=201; body='{"receipt_token":"receipt-token","created_at":"2026-08-29T00:00:00Z"}' ;;
  'GET https://example.test/api/reviews/review-token')
    if [[ -f "$MOCK_STATE_DIR/reviewed" ]]; then
      body='{"submissions":[{"id":"submission-id","student_name":"Deployment verifier","explanation_text":"I compared both examples before choosing the second result. durability-test","confidence":4,"teacher_tags":["Clear reasoning"],"teacher_note":"Revision persistence verified for durability-test","follow_up":true}]}'
    else
      body='{"submissions":[{"id":"submission-id","student_name":"Deployment verifier","explanation_text":"I compared both examples before choosing the second result. durability-test","confidence":4,"teacher_tags":[],"teacher_note":"","follow_up":false}]}'
    fi ;;
  'PATCH https://example.test/api/reviews/review-token/submissions/submission-id')
    : > "$MOCK_STATE_DIR/reviewed"; body='{"saved":true}' ;;
  'GET https://example.test/api/receipts/receipt-token')
    body='{"student_name":"Deployment verifier","explanation_text":"I compared both examples before choosing the second result. durability-test","confidence":4}' ;;
  'GET https://example.test/health')
    body='{"status":"ok","build_sha":"expected-sha"}' ;;
  *) echo "unexpected curl request: $method $url" >&2; exit 1 ;;
esac
printf '%s' "$body" > "$output"
printf '%s' "$status"
MOCK

chmod +x "$test_dir/bin/az" "$test_dir/bin/curl"

# Make the date/PID marker deterministic so fixture JSON can prove the exact
# submission and teacher-review contents after the simulated revision restart.
sed_checker="$test_dir/checker"
sed 's/marker="durability-$(date -u +%Y%m%dT%H%M%SZ)-$$"/marker="durability-test"/' "$checker" > "$sed_checker"
chmod +x "$sed_checker"

output=$(MOCK_STATE_DIR="$test_dir/state" \
  AZ_BIN="$test_dir/bin/az" CURL_BIN="$test_dir/bin/curl" \
  DURABILITY_READ_ATTEMPTS=3 DURABILITY_REVISION_ATTEMPTS=2 \
  DURABILITY_REVISION_INTERVAL_SECONDS=0 \
  "$sed_checker" https://example.test app group expected-sha durable durable-share)

jq -e '
  .result == "PASS"
  and .previous_revision == "app--0000040"
  and .revision == "app--0000041"
  and .topology.active_revisions == 1
  and .topology.storage_name == "durable"
  and .topology.share_name == "durable-share"
  and .before_new_revision.student_reads_200 == 3
  and .before_new_revision.review_reads_200 == 3
  and .before_new_revision.receipt_reads_200 == 3
  and .before_new_revision.submission_status == 201
  and .before_new_revision.review_saved == true
  and .after_new_revision.student_reads_200 == 3
  and .after_new_revision.review_reads_200 == 3
  and .after_new_revision.receipt_reads_200 == 3
  and .after_new_revision.submission_and_review_persisted == true
' >/dev/null <<<"$output"
grep -Fq 'containerapp update' "$test_dir/state/az.log"
[[ $(grep -Fc 'GET https://example.test/api/checkins/student-token' "$test_dir/state/curl.log") == 6 ]]
[[ $(grep -Fc 'GET https://example.test/api/reviews/review-token' "$test_dir/state/curl.log") == 8 ]]
[[ $(grep -Fc 'GET https://example.test/api/receipts/receipt-token' "$test_dir/state/curl.log") == 6 ]]

rm -rf "$test_dir/state"
mkdir -p "$test_dir/state"
if MOCK_STATE_DIR="$test_dir/state" MOCK_FAIL_PRIVATE_READ=1 \
  AZ_BIN="$test_dir/bin/az" CURL_BIN="$test_dir/bin/curl" \
  DURABILITY_READ_ATTEMPTS=1 DURABILITY_REVISION_ATTEMPTS=2 \
  DURABILITY_REVISION_INTERVAL_SECONDS=0 \
  "$sed_checker" https://example.test app group expected-sha durable durable-share \
  >"$test_dir/failure.out" 2>&1; then
  echo 'live durability checker accepted a reproduced private-link 404' >&2
  exit 1
fi
grep -Fq 'student-link read 1/1 returned 404, expected 200' "$test_dir/failure.out"

echo 'PASS: live durability checker covers student, review, and receipt reads across a new revision'
