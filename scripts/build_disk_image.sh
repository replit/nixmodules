#!/usr/bin/env bash
set -eo pipefail

# This script:
# 1. builds nixmodules disk image bundle from github:replit/nixmodules for the given rev
# 2. uploads image to gcs
# 3. builds squashfs disk image bundle (for dev)
# 4. uploads squashfs image to gcs

# To run, make sure you are logged in via:
# gcloud auth login

rev=$(nix build --refresh --quiet .#rev --print-out-paths $NIX_FLAGS| xargs cat)

img_name="nixmodules-${rev}"
gcs_path="gs://nixmodules/$img_name.tar.gz"
# squashfs is used in Goval CI and local dev
gcs_path_squashfs="gs://nixmodules/nixmodules.sqsh"

# exit early if it already exists
gsutil ls "$gcs_path" 2>/dev/null && exit 0

img_path=$(nix build .#bundle-image-tarball --no-update-lock-file $NIX_FLAGS --print-out-paths)/disk.raw.tar.gz

# TODO determine if it is cheaper to upload to separate asia and us buckets
gsutil -o "GSUtil:parallel_composite_upload_threshold=150M" cp "${img_path}" "${gcs_path}"

squashfs_path=$(nix build .#bundle-squashfs $NIX_FLAGS --print-out-paths)/disk.sqsh
gsutil -o "GSUtil:parallel_composite_upload_threshold=150M" cp "${squashfs_path}" "${gcs_path_squashfs}"
