#!/usr/bin/env nix-shell
#! nix-shell -i bash -p google-cloud-sdk

# This script:
# 1. create disk images
# 2. create persistent disks
# 3. delete disk images (cleanup)

rev=$(nix build --refresh --quiet .#rev --print-out-paths $NIX_FLAGS| xargs cat)

echo "Provisioning nixmodules persistent disks..."

PROJECT="marine-cycle-160323"
img_name="nixmodules-${rev}"
gcs_path="gs://nixmodules/$img_name.tar.gz"
# fixed_gcs_path is used in Goval CI

labels="sha=${rev},service=nixmodules,component=nixmodules,cost-center=platform_packager,environment=production"

function create_image() {
  local IMAGE_STORAGE_LOCATION=$1
  gcloud compute images create \
    --source-uri "${gcs_path}" \
    --family="nixmodules" \
    --storage-location "${IMAGE_STORAGE_LOCATION}" \
    --project="${PROJECT}" \
    --labels="${labels}" \
    "${img_name}-${IMAGE_STORAGE_LOCATION}"
}

echo "Creating images..."

create_image "us"
create_image "asia"

function create_disk() {
  local IMAGE_STORAGE_LOCATION=$1
  local ZONE=$2
  gcloud compute disks create \
    --type=pd-ssd \
    --image="${img_name}-${IMAGE_STORAGE_LOCATION}" \
    --zone="${ZONE}" \
    --project="${PROJECT}" \
    --labels="${labels}" \
    "${img_name}-${ZONE}"
}

echo "Creating disks..."

create_disk "asia" "asia-south1-a"
create_disk "asia" "asia-south1-b"

create_disk "us" "us-west1-a"
create_disk "us" "us-west1-b"
create_disk "us" "us-west1-c"

create_disk "us" "us-central1-a"
create_disk "us" "us-central1-c"
create_disk "us" "us-central1-f"

create_disk "us" "us-east1-b"
create_disk "us" "us-east1-c"
create_disk "us" "us-east1-d"

echo "nixmodules disks provisioned"
