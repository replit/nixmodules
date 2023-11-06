set -o xtrace
. .attrs.sh

PATH="${env[PATH]}"
out="${outputs[out]}"

mkdir "$out"

root="$PWD/root"
mkdir -p "$root/nix/store" "$root/etc/nixmodules"

cp --archive --reflink=auto "${env["bundle-locked"]}/etc/nixmodules/"* "$root/etc/nixmodules"

xargs -I % cp -a --reflink=auto % "$root/nix/store/" < "${env[diskClosureInfo]}"/store-paths

diskImage=$out/${env[diskName]}

echo "making squashfs..."
mksquashfs "$root" "$diskImage" -force-uid 11000 -force-gid 11000
