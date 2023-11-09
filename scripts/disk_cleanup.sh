#!/usr/bin/env bash
set -eo pipefail

PROJECT="marine-cycle-160323"

echo "Looking for disks..."

# only delete disks where the disk SHA is unused across the entire
# fleet
disks_to_delete=($( \
  gcloud compute disks list \
    --project=$PROJECT \
    --filter="name~nixmodules-'.*' AND name!~'.*'-semaphore-'.*'" \
    --format "json(selfLink,labels.sha,users)" | \
  jq -r '
  reduce .[] as $d
    ({};
        .[$d.labels.sha].uris += [$d.selfLink]
      | .[$d.labels.sha].users += $d.users
      )
  | to_entries
  | map(.value)
  | map(select(.users == null))
  | map(.uris)
  | flatten
  | unique
  | join(" ")
'))

if [[ -z "${disks_to_delete}" ]]
then
  echo "No disks to delete."
  exit 0
fi

echo "Clearing disks..."

# Calculate the number of chunks
num_chunks=$(("${#disks_to_delete[@]}" / 20))

# Minimum of 1
num_chunks=$((num_chunks==0 ? 1 : num_chunks))

# Loop over the chunks
for (( i = 0; i < ${num_chunks}; i++ )); do

  # Get the start and end indices of the current chunk
  start_index=$((i * 20))
  end_index=$((i * 20 + 19))

  gcloud compute disks delete "${disks_to_delete[@]:$start_index:$end_index}"
done
