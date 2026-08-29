#!/usr/bin/env bash
# Deploy the product through the factory helper, then attach its own Azure File
# share and pin it to one SQLite writer. SQLite cannot safely be replicated via
# independent container filesystems.
set -euo pipefail

slug=${1:-accessible-explanation-checkin}
repo=${2:-/work/repo}
dockerfile=${3:-Dockerfile}
port=${4:-8080}
fleet_deploy_helper=${FLEET_DEPLOY_CONTAINER_HELPER:-/opt/fleet/lib/deploy-container.sh}
resource_group=${AZURE_RESOURCE_GROUP:-sociobot}
environment=${AZURE_CONTAINERAPP_ENV:-factory-env}
storage_account=${AZURE_STORAGE_ACCOUNT:-sociobotblob}

app_name="sf-$slug"
if [ ${#app_name} -gt 32 ]; then
  app_name="sf-${slug:0:22}-$(printf '%s' "$slug" | sha1sum | cut -c1-6)"
  app_name=${app_name//--/-}
fi
storage_name="${slug}-data"
if [ ${#storage_name} -gt 32 ]; then
  storage_name="aec-${slug:0:20}-$(printf '%s' "$slug" | sha1sum | cut -c1-6)"
  storage_name=${storage_name//--/-}
fi
share_name="sf-${slug}-data"

"$fleet_deploy_helper" "$slug" "$repo" "$dockerfile" "$port"

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
  | .scale = {minReplicas: 1, maxReplicas: 1}
  | .volumes = [{name: "checkin-data", storageType: "AzureFile", storageName: $storage}]
  | .containers |= map(if .name == "app" then .volumeMounts = [{volumeName: "checkin-data", mountPath: "/app/data"}] else . end)
' <<<"$app")
payload=$(jq -n --argjson template "$template" '{properties:{template:$template}}')
subscription=$(az account show --query id --output tsv)
az rest --method patch \
  --url "https://management.azure.com/subscriptions/$subscription/resourceGroups/$resource_group/providers/Microsoft.App/containerApps/$app_name?api-version=2024-03-01" \
  --body "$payload" --output none

# Do not report a successful deployment until the control plane returns the
# effective topology. The generic factory deploy deliberately creates a
# stateless 1–3 replica template, so this verification prevents that
# intermediate template from being mistaken for the final SQLite deployment.
verified=false
for _ in $(seq 1 "${DEPLOY_VERIFY_ATTEMPTS:-30}"); do
  effective=$(az containerapp show --resource-group "$resource_group" --name "$app_name" --output json)
  if jq -e --arg storage "$storage_name" '
    (.properties.latestRevisionName | length) > 0
    and .properties.latestRevisionName == .properties.latestReadyRevisionName
    and .properties.template.scale.minReplicas == 1
    and .properties.template.scale.maxReplicas == 1
    and any(.properties.template.volumes[]?;
      .name == "checkin-data"
      and .storageType == "AzureFile"
      and .storageName == $storage)
    and any(.properties.template.containers[]?;
      .name == "app"
      and any(.volumeMounts[]?;
        .volumeName == "checkin-data"
        and .mountPath == "/app/data"))
  ' >/dev/null <<<"$effective"; then
    verified=true
    break
  fi
  sleep "${DEPLOY_VERIFY_INTERVAL_SECONDS:-10}"
done

if [[ "$verified" != true ]]; then
  echo "ERROR: $app_name did not reach a ready revision with one replica and durable /app/data" >&2
  exit 1
fi

latest_revision=$(jq -r '.properties.latestRevisionName' <<<"$effective")
while IFS= read -r stale_revision; do
  [[ -z "$stale_revision" || "$stale_revision" == "$latest_revision" ]] && continue
  az containerapp revision deactivate --resource-group "$resource_group" \
    --name "$app_name" --revision "$stale_revision" --output none
done < <(az containerapp revision list --resource-group "$resource_group" \
  --name "$app_name" --query '[?properties.active].name' --output tsv)

replicas_verified=false
for _ in $(seq 1 "${DEPLOY_VERIFY_ATTEMPTS:-30}"); do
  active_revisions=$(az containerapp revision list --resource-group "$resource_group" \
    --name "$app_name" --query 'length([?properties.active])' --output tsv)
  running_replicas=$(az containerapp replica list --resource-group "$resource_group" \
    --name "$app_name" --revision "$latest_revision" \
    --query "length([?properties.runningState=='Running'])" --output tsv)
  if [[ "$active_revisions" == 1 && "$running_replicas" == 1 ]]; then
    replicas_verified=true
    break
  fi
  sleep "${DEPLOY_VERIFY_INTERVAL_SECONDS:-10}"
done

if [[ "$replicas_verified" != true ]]; then
  echo "ERROR: $app_name did not converge to exactly one active, running replica" >&2
  exit 1
fi

echo "PASS: deployed and verified $app_name with durable /app/data and exactly one SQLite replica"
