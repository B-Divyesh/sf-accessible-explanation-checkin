#!/usr/bin/env bash
# Regression coverage for the fleet deploy helper. It executes the real helper
# against mocked Azure/DNS commands so a long product slug never reaches Azure
# as an invalid Container App name.
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

echo "PASS: $slug maps deterministically to $actual (${#actual} characters)"
