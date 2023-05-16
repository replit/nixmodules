set -eou pipefail
. .attrs.sh

PATH="${env[PATH]}"
out="${outputs[out]}"

mkdir "$out"

root="$PWD/root"
mkdir -p "$root/nix/store" "$root/etc/nixmodules"

xargs -I % cp -a --reflink=auto % "$root/nix/store/" < "${env[diskClosureInfo]}"/store-paths

cp -a --reflink=auto "${env[registry]}" "$root/etc/nixmodules/modules.json"

echo "making squashfs..."
mksquashfs "$root" "$out/disk.sqsh"
