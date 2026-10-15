#!/usr/bin/env bash
set -euo pipefail

bundle="$1"
store_paths="$2"
output="$3"
architecture="$4"
metadata="$5"
layout_script="$6"

mkdir -p root/nix/store root/etc/nixmodules "$output/blobs/sha256"
cp -a --reflink=auto "$bundle/etc/nixmodules/." root/etc/nixmodules/
while IFS= read -r path; do
  cp -a --reflink=auto "$path" root/nix/store/
done < "$store_paths"
chmod 755 root root/nix root/nix/store root/etc root/etc/nixmodules

mkfs.erofs -U 00000000-0000-0000-0000-000000000001 -T 1 \
  --force-uid=11000 --force-gid=11000 -E noinline_data raw.erofs root
zstd -15 --long=27 -T8 --check --no-progress --quiet raw.erofs -o layer.erofs.zst
python3 "$layout_script" raw.erofs layer.erofs.zst "$output" "$architecture" "$metadata"
