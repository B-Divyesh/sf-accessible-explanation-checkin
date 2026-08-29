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
  cat <<'JSON'
{"properties":{"latestRevisionName":"app--0000040","latestReadyRevisionName":"app--0000040","template":{"scale":{"minReplicas":1,"maxReplicas":1},"volumes":[{"name":"checkin-data","storageType":"AzureFile","storageName":"durable"}],"containers":[{"name":"app","volumeMounts":[{"volumeName":"checkin-data","mountPath":"/app/data"}]}]}}}
JSON
elif [[ "$args" == "containerapp replica list"* ]]; then
  printf '1\n'
elif [[ "$args" == "containerapp revision restart"* ]]; then
  : > "$MOCK_STATE_DIR/restarted"
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
    --silent|--show-error) shift ;;
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
      body='{"submissions":[{"id":"submission-id","student_name":"Deployment verifier","explanation_text":"I compared both examples before choosing the second result. durability-test","confidence":4,"teacher_tags":["Clear reasoning"],"teacher_note":"Restart persistence verified for durability-test","follow_up":true}]}'
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
  DURABILITY_READ_ATTEMPTS=3 DURABILITY_RESTART_ATTEMPTS=1 \
  DURABILITY_RESTART_INTERVAL_SECONDS=0 \
  "$sed_checker" https://example.test app group expected-sha)

jq -e '
  .result == "PASS"
  and .before_restart.student_reads_200 == 3
  and .before_restart.review_reads_200 == 3
  and .before_restart.submission_status == 201
  and .before_restart.review_saved == true
  and .after_revision_restart.student_reads_200 == 3
  and .after_revision_restart.review_reads_200 == 3
  and .after_revision_restart.submission_and_review_persisted == true
' >/dev/null <<<"$output"
grep -Fq 'containerapp revision restart' "$test_dir/state/az.log"
[[ $(grep -Fc 'GET https://example.test/api/checkins/student-token' "$test_dir/state/curl.log") == 6 ]]
[[ $(grep -Fc 'GET https://example.test/api/reviews/review-token' "$test_dir/state/curl.log") == 8 ]]

rm -rf "$test_dir/state"
mkdir -p "$test_dir/state"
if MOCK_STATE_DIR="$test_dir/state" MOCK_FAIL_PRIVATE_READ=1 \
  AZ_BIN="$test_dir/bin/az" CURL_BIN="$test_dir/bin/curl" \
  DURABILITY_READ_ATTEMPTS=1 DURABILITY_RESTART_ATTEMPTS=1 \
  DURABILITY_RESTART_INTERVAL_SECONDS=0 \
  "$sed_checker" https://example.test app group expected-sha \
  >"$test_dir/failure.out" 2>&1; then
  echo 'live durability checker accepted a reproduced private-link 404' >&2
  exit 1
fi
grep -Fq 'student-link read 1/1 returned 404, expected 200' "$test_dir/failure.out"

echo 'PASS: live durability checker covers repeated private reads, submit/review, and revision-restart persistence'
