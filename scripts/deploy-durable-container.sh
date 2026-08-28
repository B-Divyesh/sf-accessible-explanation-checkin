#!/usr/bin/env bash
# Deploy the product through the factory helper, then attach its own Azure File
# share and pin it to one SQLite writer. SQLite cannot safely be replicated via
# independent container filesystems.
set -euo pipefail

slug=${1:-accessible-explanation-checkin}
repo=${2:-/work/repo}
dockerfile=${3:-Dockerfile}
port=${4:-8080}
resource_group=${AZURE_RESOURCE_GROUP:-sociobot}
environment=${AZURE_CONTAINERAPP_ENV:-factory-env}
storage_account=${AZURE_STORAGE_ACCOUNT:-sociobotblob}

app_name="sf-$slug"
if [ ${#app_name} -gt 32 ]; then
  app_name="sf-${slug:0:22}-$(printf '%s' "$slug" | sha1sum | cut -c1-6)"
  app_name=${app_name//--/-}
fi
storage_name="${slug}-data"
share_name="sf-${slug}-data"

/opt/fleet/lib/deploy-container.sh "$slug" "$repo" "$dockerfile" "$port"

# These operations are idempotent. The access key is handed only to Azure's
# managed-environment storage registration, never to the container image.
storage_key=$(az storage account keys list --resource-group "$resource_group" --account-name "$storage_account" --query '[0].value' --output tsv)
az storage share create --name "$share_name" --account-name "$storage_account" --account-key "$storage_key" --output none
az containerapp env storage set --resource-group "$resource_group" --name "$environment" \
  --storage-name "$storage_name" --access-mode ReadWrite \
  --azure-file-account-name "$storage_account" --azure-file-share-name "$share_name" \
  --azure-file-account-key "$storage_key" --output none

app=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
template=$(jq --arg storage "$storage_name" '
  .properties.template
  | .scale.minReplicas = 1
  | .scale.maxReplicas = 1
  | .volumes = [{name: "checkin-data", storageType: "AzureFile", storageName: $storage}]
  | .containers |= map(if .name == "app" then .volumeMounts = [{volumeName: "checkin-data", mountPath: "/app/data"}] else . end)
' <<<"$app")
payload=$(jq -n --argjson template "$template" '{properties:{template:$template}}')
subscription=$(az account show --query id --output tsv)
az rest --method patch \
  --url "https://management.azure.com/subscriptions/$subscription/resourceGroups/$resource_group/providers/Microsoft.App/containerApps/$app_name?api-version=2024-03-01" \
  --body "$payload" --output none

echo "PASS: deployed $app_name with durable /app/data and exactly one SQLite replica"
