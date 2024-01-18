#!/usr/bin/env bash
set -eo pipefail

# This script:
# 1. builds nixmodules disk image bundle from github:replit/nixmodules for the given rev
# 2. uploads image to gcs
# 3. builds squashfs disk image bundle (for dev)
# 4. uploads squashfs image to gcs

# To run, make sure you are logged in via:
# gcloud auth login

# We've been having some authentication-related issues. Sledgehammer to figure out what's wrong.
if hash md5sum; then
  md5sum $(nix --extra-experimental-features nix-command show-config netrc-file) || true
elif hash md5; then
  md5 $(nix --extra-experimental-features nix-command show-config netrc-file) || true
fi

rev=$(nix build --refresh --quiet .#rev --print-out-paths $NIX_FLAGS| xargs cat)

img_name="nixmodules-${rev}"
gcs_path="gs://nixmodules/$img_name.tar.gz"
# squashfs is used in Goval CI and local dev
gcs_path_dev="gs://nixmodules/dev/${img_name}.sqsh"

# exit early if it already exists
gsutil ls "$gcs_path" 2>/dev/null && exit 0

img_path=$(nix build .#bundle-image-tarball $NIX_FLAGS --print-out-paths)/disk.raw.tar.gz

# TODO determine if it is cheaper to upload to separate asia and us buckets
gsutil -o "GSUtil:parallel_composite_upload_threshold=150M" cp "${img_path}" "${gcs_path}"

dev_path=$(nix build .#bundle-squashfs $NIX_FLAGS --print-out-paths)/disk.sqsh
gsutil -o "GSUtil:parallel_composite_upload_threshold=150M" cp "${dev_path}" "${gcs_path_dev}"
