#!/usr/bin/env bash
set -euo pipefail

script=${1:-scripts/deploy-durable-container.sh}
grep -Fq 'storageType: "AzureFile"' "$script"
grep -Fq 'mountPath: "/app/data"' "$script"
grep -Fq '.scale = {minReplicas: 1, maxReplicas: 1}' "$script"
grep -Fq 'deploy-container.sh' "$script"
grep -Fq 'storage_name="aec-${slug:0:20}-$(printf' "$script"
echo 'PASS @claim:durable-deployment-policy: durable deployment pins SQLite to one Azure File-backed replica'
