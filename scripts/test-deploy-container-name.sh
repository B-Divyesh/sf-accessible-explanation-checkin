#!/usr/bin/env bash
# Regression coverage for the fleet deploy helper. It executes the real helper
# against mocked Azure/DNS commands so a long product slug never reaches Azure
# as an invalid Container App name or managed-environment storage alias.
set -euo pipefail

helper=${FLEET_DEPLOY_CONTAINER_HELPER:-/opt/fleet/lib/deploy-container.sh}
slug=accessible-explanation-checkin

[[ -x "$helper" ]] || { echo "deploy helper is not executable: $helper" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/source"

printf '%s\n' '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'args="$*"' \
  'if [[ "$args" =~ /managedEnvironments/[^/]+/storages/([^?[:space:]]+) ]]; then' \
  '  storage_name="${BASH_REMATCH[1]}"' \
  '  if (( ${#storage_name} > 32 )); then' \
  '    echo "Managed environment storage alias exceeds 32 characters: $storage_name" >&2' \
  '    exit 2' \
  '  fi' \
  'fi' \
  'if [[ "$args" == *"managedCertificates"* && "$args" == *"--query properties.provisioningState"* ]]; then' \
  '  printf "%s\\n" "Succeeded"' \
  'elif [[ "$args" == *"-m get"* && "$args" == *"/containerApps/"* ]]; then' \
  '  printf "%s\\n" '\''{"properties":{"provisioningState":"Succeeded","configuration":{"ingress":{"fqdn":"mock.example"}},"customDomainVerificationId":"mock-verification"}}'\''' \
  'fi' > "$work/bin/az"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s" "200"' > "$work/bin/curl"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$work/bin/sleep"
chmod +x "$work/bin/az" "$work/bin/curl" "$work/bin/sleep"

output=$(PATH="$work/bin:$PATH" "$helper" "$slug" "$work/source" Dockerfile 8080 'example.invalid/prebuilt:latest')
actual=$(sed -n 's/^== container app name: \([^ ]*\) (slug .*/\1/p' <<<"$output")
expected="sf-${slug:0:22}-$(printf '%s' "$slug" | sha1sum | cut -c1-6)"
expected=${expected//--/-}

[[ "$actual" == "$expected" ]] || { echo "expected $expected, got $actual" >&2; exit 1; }
[[ ${#actual} -le 32 ]] || { echo "Container App name is ${#actual} characters: $actual" >&2; exit 1; }
[[ "$output" == *"https://$slug.sociobot.in -> 200"* ]] || { echo "helper did not complete custom-domain probe" >&2; exit 1; }

# Reproduce the original Azure Files deployment failure in a disposable copy of
# the old helper: its unshortened sf-<slug>-data alias is rejected before a
# Container App can be published. The real helper must instead choose its
# deterministic shortened storage alias when deploy.data_dir is /data.
legacy_helper="$work/legacy-deploy-container.sh"
cp "$helper" "$legacy_helper"
sed -i '/^DEFAULT_STORAGE="sf-\$SLUG-data"$/,/^fi$/c\DEFAULT_STORAGE="sf-$SLUG-data"' "$legacy_helper"
chmod +x "$legacy_helper"

legacy_storage="sf-$slug-data"
[[ ${#legacy_storage} -gt 32 ]] || { echo "legacy storage fixture is not over the Azure limit" >&2; exit 1; }
if WO_DATA_DIR=/data PATH="$work/bin:$PATH" "$legacy_helper" "$slug" "$work/source" Dockerfile 8080 'example.invalid/prebuilt:latest' >"$work/legacy.out" 2>&1; then
  echo 'legacy unshortened Azure Files alias unexpectedly deployed' >&2
  exit 1
fi
grep -Fq "Managed environment storage alias exceeds 32 characters: $legacy_storage" "$work/legacy.out"

storage_output=$(WO_DATA_DIR=/data PATH="$work/bin:$PATH" "$helper" "$slug" "$work/source" Dockerfile 8080 'example.invalid/prebuilt:latest')
storage_actual=$(sed -n 's/^== durable share \([^ ]*\) for \/data$/\1/p' <<<"$storage_output")
storage_expected="sf-${slug:0:21}-$(printf '%s' "$slug" | sha1sum | cut -c1-6)"
storage_expected=${storage_expected//--/-}

[[ "$storage_actual" == "$storage_expected" ]] || { echo "expected storage alias $storage_expected, got $storage_actual" >&2; exit 1; }
[[ ${#storage_actual} -le 32 ]] || { echo "Storage alias is ${#storage_actual} characters: $storage_actual" >&2; exit 1; }
[[ "$storage_actual" != "$legacy_storage" ]] || { echo 'storage alias was not shortened' >&2; exit 1; }
[[ "$storage_output" == *"https://$slug.sociobot.in -> 200"* ]] || { echo "helper did not finish durable deployment probe" >&2; exit 1; }

echo "PASS: $slug maps deterministically to app $actual and /data storage $storage_actual (both <= 32 characters)"
