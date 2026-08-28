#!/usr/bin/env bash
set -euo pipefail

script=${1:-scripts/deploy-durable-container.sh}
grep -Fq 'storageType: "AzureFile"' "$script"
grep -Fq 'mountPath: "/app/data"' "$script"
grep -Fq '.scale.minReplicas = 1' "$script"
grep -Fq '.scale.maxReplicas = 1' "$script"
grep -Fq 'deploy-container.sh' "$script"
echo 'PASS: durable deployment pins SQLite to one Azure File-backed replica'
