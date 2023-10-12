#!/usr/bin/env bash

# This script is ran by Semaphore to hand off to Prodvana to roll out the new version.

set -evxo pipefail

rev=$(nix build --refresh --quiet .#rev --print-out-paths $NIX_FLAGS| xargs cat)
SERVICE_NAME=nixmodules
APPLICATION_NAME=nixmodules

# check existence of disk
img_name="nixmodules-${rev}"

function check_disks() {
  local PROJECT=$1
  disks=$(gcloud compute disks list --project=$PROJECT --filter="name~${img_name}'.*'" --format="value(name)")

  if [[ ! $disks ]]; then
    echo "Disks for ${img_name} do not exist. Exiting."
    exit 1
  fi
}

check_disks marine-cycle-160323
check_disks replit-platform-staging
check_disks replit-platform-prod

echo "Triggering ship-it-bot webhook"

cat <<EOF >payload.json
{
    "commit_sha": "$SEMAPHORE_GIT_SHA",
    "docker_sha": "latest",
    "nixmodules_version": "$img_name",
    "jitter":  "3600s"
}
EOF

curl -X POST \
    -H "Authorization: $SHIP_IT_BOT_AUTH" \
    -H "content-type: application/json" \
    -H "CF-Access-Client-Secret: $CF_CLIENT_SECRET" \
    -H "CF-Access-Client-Id: $CF_CLIENT_ID" \
    -d @payload.json \
    $DEPLOY_URL/deploy/$APPLICATION_NAME/$SERVICE_NAME
