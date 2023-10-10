set -eou pipefail
. .attrs.sh

PATH="${env[PATH]}"
out="${outputs[out]}"

mkdir "$out"

root="$PWD/root"
mkdir -p "$root/nix/store" "$root/etc/nixmodules"

xargs -I % cp -a --reflink=auto % "$root/nix/store/" < "${env[diskClosureInfo]}"/store-paths

cp "${env["upgrade-maps"]}/auto-upgrade.json" $root/etc/nixmodules/auto-upgrade.json
cp "${env["upgrade-maps"]}/recommend-upgrade.json" $root/etc/nixmodules/recommend-upgrade.json
cp "${env["active-modules"]}" $root/etc/nixmodules/active-modules.json
echo "${env[registry]}" > "$root/etc/nixmodules/modules.json"

echo "making squashfs..."
mksquashfs "$root" "$out/disk.sqsh" -force-uid 11000 -force-gid 11000
